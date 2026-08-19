import AppKit
import ApplicationServices
import SwiftUI

// MARK: - Shelf mode

/// Picks when the shelf appears, writing straight into `Preferences`.
///
/// Deliberately a real setting rather than a preview: what is chosen here stays
/// chosen, so the guide leaves behind a configured app, not a tour.
struct ShelfModePicker: View {
    @EnvironmentObject private var preferences: Preferences

    var body: some View {
        VStack(spacing: 8) {
            Text("Choose how iPaste appears")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.white.opacity(0.48))

            HStack(spacing: 6) {
                ForEach(ShelfMode.allCases) { mode in
                    option(mode)
                }
            }
        }
    }

    private func option(_ mode: ShelfMode) -> some View {
        let isActive = preferences.shelfMode == mode
        return Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                preferences.shelfMode = mode
            }
        } label: {
            VStack(spacing: 2) {
                Text(title(for: mode))
                    .font(.system(size: 12, weight: .medium))
                Text(caption(for: mode))
                    .font(.system(size: 9))
                    .opacity(0.7)
                    .lineLimit(1)
                    .minimumScaleFactor(0.88)
            }
            .foregroundStyle(isActive ? Color.white : Color.white.opacity(0.7))
            .frame(width: 146, height: 46)
            .background {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(isActive ? OnboardingStyle.accent : Color.white.opacity(0.055))
            }
            .overlay {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(Color.white.opacity(isActive ? 0.16 : 0.08), lineWidth: 1)
            }
            .shadow(color: isActive ? OnboardingStyle.accent.opacity(0.2) : .clear, radius: 10, y: 4)
        }
        .buttonStyle(.plain)
    }

    /// Wording that belongs to the guide: `ShelfMode.label` stays the app own.
    private func title(for mode: ShelfMode) -> String {
        switch mode {
        case .always:  return "Always"
        case .onHover: return "On Hover"
        case .never:   return "Shortcut"
        }
    }

    private func caption(for mode: ShelfMode) -> String {
        switch mode {
        case .always:  return "Stays visible"
        case .onHover: return "Recommended"
        case .never:   return "Press ⌃⌘S"
        }
    }
}

// MARK: - Accessibility

/// Live Accessibility permission state, plus the button that asks for it.
///
/// macOS never tells us when the permission is granted, and it only lands after
/// the user acts in System Settings — so we poll while this step is on screen.
struct AccessibilityControl: View {
    @Binding var granted: Bool
    var onRequest: () -> Void

    private let ticker = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(spacing: 9) {
            if granted {
                statusPill
                Text("iPaste can now paste directly into other apps.")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.white.opacity(0.58))
            } else {
                HStack(spacing: 18) {
                    instruction(1, "Open Settings")
                    instruction(2, "Turn on iPaste")
                    instruction(3, "Return here")
                }

                Button("Open Settings", action: onRequest)
                    .buttonStyle(OnboardingPrimaryStyle())

                Text("You can also continue and use ⌘V yourself.")
                    .font(.system(size: 10))
                    .foregroundStyle(.white.opacity(0.34))
            }
        }
        .onReceive(ticker) { _ in
            let current = AXIsProcessTrusted()
            guard current != granted else { return }
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) { granted = current }
        }
    }

    private func instruction(_ number: Int, _ text: String) -> some View {
        HStack(spacing: 6) {
            Text("\(number)")
                .font(.system(size: 8, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .frame(width: 18, height: 18)
                .background(OnboardingStyle.accent, in: Circle())
            Text(text)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(.white.opacity(0.62))
        }
    }

    private var statusPill: some View {
        HStack(spacing: 7) {
            Circle()
                .fill(granted ? Color.green : Color.orange)
                .frame(width: 7, height: 7)
            Text(granted ? "Accessibility granted" : "Not granted yet")
                .font(.system(size: 12, weight: .medium))
        }
        .padding(.horizontal, 12)
        .frame(height: 28)
        .background(Capsule().fill(Color.white.opacity(0.07)))
        .overlay { Capsule().strokeBorder(Color.white.opacity(0.08), lineWidth: 1) }
    }
}

// MARK: - Final

/// The cheat sheet the user leaves with, plus the launch-at-login switch.
struct ReadySummary: View {
    @State private var launchesAtLogin = LoginItem.isEnabled

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 26) {
                VStack(alignment: .leading, spacing: 6) {
                    ShortcutLine(keys: ["⌃", "⌘", "V"], caption: "quick search")
                    ShortcutLine(keys: ["⌃", "⌘", "S"], caption: "show or hide the shelf")
                }
                VStack(alignment: .leading, spacing: 6) {
                    ShortcutLine(keys: ["⌃", "⌘", "0"], caption: "use the latest clip")
                }
            }

            if LoginItem.isAvailable {
                Toggle(isOn: $launchesAtLogin) {
                    Text("Start iPaste when I log in")
                        .font(.system(size: 12))
                }
                .toggleStyle(.switch)
                .controlSize(.small)
                .fixedSize()
                // The switch follows the system, not the request: if registration
                // fails it snaps back instead of lying about the real state.
                .onChange(of: launchesAtLogin) { _, wanted in
                    let actual = LoginItem.setEnabled(wanted)
                    if actual != wanted { launchesAtLogin = actual }
                }
            }
        }
    }
}
