import Foundation

/// The steps of the first-run guide, in the order they appear.
///
/// The order is deliberate: show what the user gains first, ask for Accessibility
/// permission only at the end. A system dialog in the first second, before the app
/// has shown anything at all, is the surest way to be denied.
enum OnboardingStep: Int, CaseIterable, Identifiable {
    case welcome
    case capture
    case search
    case shelf
    case library
    case permission
    case ready

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .welcome:    return "Welcome to iPaste"
        case .capture:    return "It remembers everything you copy"
        case .search:     return "Find anything in two keys"
        case .shelf:      return "The shelf next to the notch"
        case .library:    return "Your history, right in the notch"
        case .permission: return "One permission to grant"
        case .ready:      return "You're all set"
        }
    }

    var subtitle: String {
        switch self {
        case .welcome:
            return "The macOS clipboard holds one thing at a time. iPaste keeps them all and hands them back in seconds. Nothing ever leaves your Mac."
        case .capture:
            return "Text, links, code, colors, images, files — iPaste recognizes what you copied and files it under the right kind."
        case .search:
            return "⌃⌘V opens search anywhere. Type, pick with the arrow keys, press Enter and it pastes into the app you came from."
        case .shelf:
            return "Move the cursor to the top edge and the shelf drops out of the notch with your latest clips. Drag them straight where you need them."
        case .library:
            return "Use the notch shelf to browse your latest clips, switch between cards and list view, and search your history without opening another window."
        case .permission:
            return "To paste into the active app, iPaste sends a ⌘V keystroke. macOS requires Accessibility access for that."
        case .ready:
            return "That's it. iPaste lives in the menu bar, top right, and starts watching the clipboard right away."
        }
    }

    /// The primary button label — the last step starts the app, it does not continue.
    var primaryLabel: String {
        self == .ready ? "Start using iPaste" : "Continue"
    }

    var next: OnboardingStep? { OnboardingStep(rawValue: rawValue + 1) }
    var previous: OnboardingStep? { OnboardingStep(rawValue: rawValue - 1) }
}
