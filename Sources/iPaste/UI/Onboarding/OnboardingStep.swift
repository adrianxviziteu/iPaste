import Foundation

/// The steps of the first-run guide, in the order they appear.
///
/// The order is deliberate: show what the user gains first, ask for Accessibility
/// permission only at the end. A system dialog in the first second, before the app
/// has shown anything at all, is the surest way to be denied.
enum OnboardingStep: Int, CaseIterable, Identifiable {
    case welcome
    case capture
    case shelf
    case permission
    case ready

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .welcome:    return "Meet iPaste"
        case .capture:    return "Your clipboard, remembered"
        case .shelf:      return "Always within reach"
        case .permission: return "Paste with one click"
        case .ready:      return "iPaste is ready"
        }
    }

    var subtitle: String {
        switch self {
        case .welcome:
            return "Everything you copy, ready in your notch."
        case .capture:
            return "Text, links, colors, images, and files stay organized on your Mac."
        case .shelf:
            return "Move to the notch, choose a clip, and keep going."
        case .permission:
            return "Allow Accessibility so iPaste can paste directly into the app you are using."
        case .ready:
            return "Copy something. Your history starts now."
        }
    }

    /// The last step starts the app instead of advancing.
    var primaryLabel: String {
        self == .ready ? "Get Started" : "Continue"
    }

    var next: OnboardingStep? { OnboardingStep(rawValue: rawValue + 1) }
    var previous: OnboardingStep? { OnboardingStep(rawValue: rawValue - 1) }
}
