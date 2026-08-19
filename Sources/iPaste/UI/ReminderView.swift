import SwiftUI

/// Shared by the shelf, quick search, and library menus so every clip gets the
/// same reminder choices regardless of where the user finds it.
struct ClipReminderMenu: View {
    let clip: Clip

    @EnvironmentObject private var app: AppState

    var body: some View {
        Menu {
            if clip.reminder != nil {
                Button("Remove reminder") { app.removeReminder(from: clip) }
                Divider()
            }

            Button("In 1 hour") { app.remind(clip, in: 3_600) }
            Button("In 3 hours") { app.remind(clip, in: 10_800) }
            Button("Tomorrow at 9:00 AM") { app.remindTomorrow(clip) }
            Button("Custom date…") { app.showReminderPicker(for: clip) }

            if let bundleID = clip.sourceBundleID,
               app.canReturnToSourceApp(bundleID: bundleID) {
                Divider()
                Button("When I return to \(clip.sourceAppName ?? "the source app")") {
                    app.remindWhenReturningToSourceApp(clip)
                }
            }
        } label: {
            Label(
                clip.reminder == nil ? "Remind me" : "Change reminder",
                systemImage: clip.reminder == nil ? "bell" : "bell.fill"
            )
        }
    }
}

struct ReminderPickerView: View {
    let clip: Clip

    @EnvironmentObject private var app: AppState
    @State private var selectedDay: Date
    @State private var hour: Int
    @State private var minute: Int

    private let calendar = Calendar.current

    init(clip: Clip) {
        self.clip = clip
        let initial = clip.reminder?.fireDate ?? Date().addingTimeInterval(3_600)
        let calendar = Calendar.current
        _selectedDay = State(initialValue: calendar.startOfDay(for: initial))
        _hour = State(initialValue: calendar.component(.hour, from: initial))
        _minute = State(initialValue: calendar.component(.minute, from: initial) / 5 * 5)
    }

    var body: some View {
        VStack(spacing: 14) {
            header
            dayStrip
            timeControls
        }
        .padding(14)
        .frame(width: 430, height: 232)
        .background(Color(red: 0.025, green: 0.03, blue: 0.04))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(Color.white.opacity(0.12), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.45), radius: 26, y: 12)
        .environment(\.colorScheme, .dark)
    }

    private var header: some View {
        HStack(spacing: 10) {
            Button {
                app.closeReminderPicker()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.white.opacity(0.58))
                    .frame(width: 30, height: 30)
                    .background(Color.white.opacity(0.08), in: Circle())
            }
            .buttonStyle(.plain)

            Spacer()

            VStack(spacing: 2) {
                Text("Pick date & time")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white)
                Text(clip.title)
                    .font(.system(size: 9))
                    .foregroundStyle(.white.opacity(0.4))
                    .lineLimit(1)
                    .frame(maxWidth: 220)
            }

            Spacer()

            Button {
                if let date = composedDate, date > Date() {
                    app.setReminder(.at(date), for: clip)
                    app.closeReminderPicker()
                }
            } label: {
                Image(systemName: "checkmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.black)
                    .frame(width: 30, height: 30)
                    .background(Color.white, in: Circle())
            }
            .buttonStyle(.plain)
            .disabled(composedDate.map { $0 <= Date() } ?? true)
            .opacity(composedDate.map { $0 > Date() } == true ? 1 : 0.35)
        }
    }

    private var dayStrip: some View {
        HStack(spacing: 7) {
            ForEach(Array(days.enumerated()), id: \.offset) { index, day in
                Button {
                    withAnimation(.spring(response: 0.26, dampingFraction: 0.8)) {
                        selectedDay = day
                    }
                } label: {
                    VStack(spacing: 3) {
                        Text(index == 0 ? "Today" : weekday(day))
                            .font(.system(size: 8, weight: .medium))
                            .foregroundStyle(isSelected(day) ? .white.opacity(0.78) : .white.opacity(0.38))
                        Text(day.formatted(.dateTime.day()))
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(
                        isSelected(day)
                            ? Color(red: 0.20, green: 0.43, blue: 0.96)
                            : Color.white.opacity(0.065),
                        in: RoundedRectangle(cornerRadius: 11, style: .continuous)
                    )
                    .overlay {
                        RoundedRectangle(cornerRadius: 11, style: .continuous)
                            .strokeBorder(Color.white.opacity(isSelected(day) ? 0.18 : 0.06), lineWidth: 1)
                    }
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var timeControls: some View {
        HStack(spacing: 10) {
            timeControl(value: hour, label: "Hour", minus: adjustHourDown, plus: adjustHourUp)

            Text(":")
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.28))

            timeControl(value: minute, label: "Minute", minus: adjustMinuteDown, plus: adjustMinuteUp)
        }
    }

    private func timeControl(
        value: Int,
        label: String,
        minus: @escaping () -> Void,
        plus: @escaping () -> Void
    ) -> some View {
        HStack(spacing: 0) {
            Button(action: minus) {
                Image(systemName: "minus")
                    .frame(width: 34, height: 38)
            }
            .buttonStyle(.plain)

            VStack(spacing: 1) {
                Text(String(format: "%02d", value))
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                Text(label)
                    .font(.system(size: 7, weight: .medium))
                    .foregroundStyle(.white.opacity(0.3))
            }
            .frame(maxWidth: .infinity)

            Button(action: plus) {
                Image(systemName: "plus")
                    .frame(width: 34, height: 38)
            }
            .buttonStyle(.plain)
        }
        .font(.system(size: 10, weight: .semibold))
        .foregroundStyle(.white.opacity(0.75))
        .frame(maxWidth: .infinity)
        .frame(height: 44)
        .background(Color.white.opacity(0.065), in: RoundedRectangle(cornerRadius: 11, style: .continuous))
    }

    private var days: [Date] {
        let today = calendar.startOfDay(for: Date())
        return (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: today) }
    }

    private var composedDate: Date? {
        calendar.date(bySettingHour: hour, minute: minute, second: 0, of: selectedDay)
    }

    private func isSelected(_ day: Date) -> Bool {
        calendar.isDate(day, inSameDayAs: selectedDay)
    }

    private func weekday(_ day: Date) -> String {
        day.formatted(.dateTime.weekday(.narrow))
    }

    private func adjustHourDown() { hour = (hour + 23) % 24 }
    private func adjustHourUp() { hour = (hour + 1) % 24 }
    private func adjustMinuteDown() { minute = (minute + 55) % 60 }
    private func adjustMinuteUp() { minute = (minute + 5) % 60 }
}
