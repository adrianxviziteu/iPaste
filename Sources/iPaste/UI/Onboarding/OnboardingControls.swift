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
            Text("When should the shelf appear?")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.secondary)

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
                    .font(.system(size: 10))
                    .opacity(0.7)
            }
            .foregroundStyle(isActive ? Color.white : Color.primary)
            .frame(width: 128, height: 44)
            .background {
                RoundedRectangle(cornerRadius: 11, style: .continuous)
                    .fill(isActive ? Color.accentColor : Color.primary.opacity(0.06))
            }
            .overlay {
                RoundedRectangle(cornerRadius: 11, style: .continuous)
                    .strokeBorder(Color.primary.opacity(isActive ? 0 : 0.08), lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
    }

    /// Wording that belongs to the guide: `ShelfMode.label` stays the app own.
    private func title(for mode: ShelfMode) -> String {
        switch mode {
        case .always:  return "Always on"
        case .onHover: return "On hover"
        case .never:   return "Never"
        }
    }

    private func caption(for mode: ShelfMode) -> String {
        switch mode {
        case .always:  return "stays open"
        case .onHover: return "top edge · recommended"
        case .never:   return "⌃⌘S only"
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
        VStack(spacing: 12) {
            statusPill

            if granted {
                Text("iPaste can now paste into the active app.")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            } else {
                Button("Open System Settings…", action: onRequest)
                    .buttonStyle(OnboardingQuietStyle(prominent: true))

                Text("Skip it and iPaste still works — it puts the clip on the clipboard and you press ⌘V.")
                    .font(.system(size: 11))
                    .foregroundStyle(.tertiary)
                    .multilineTextAlignment(.center)
                    .frame(width: 380)
            }
        }
        .onReceive(ticker) { _ in
            let current = AXIsProcessTrusted()
            guard current != granted else { return }
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) { granted = current }
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
        .background(Capsule().fill(Color.primary.opacity(0.07)))
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
                    ShortcutLine(keys: ["⌃", "⌘", "L"], caption: "open the library")
                    ShortcutLine(keys: ["⌃", "⌘", "0"], caption: "paste the latest clip")
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
