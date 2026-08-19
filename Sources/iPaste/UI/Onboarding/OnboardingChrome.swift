import SwiftUI

// MARK: - Palette

/// Valorile comune ale ghidului.
///
/// The illustrations are mockups of the real windows, drawn from three greys and
/// a single accent. Color that says nothing is left out: in a guide, every
/// colored patch that does not mark something is noise.
enum OnboardingStyle {
    /// A mockup surface — a card, a panel, a row.
    static let surface = Color.primary.opacity(0.045)
    /// The same surface, one step raised.
    static let raised = Color.primary.opacity(0.075)
    /// The outline, as thin as the display allows.
    static let hairline = Color.primary.opacity(0.10)
}

/// The window backdrop: the system window color, nothing more. The window is
/// borderless, so the backdrop has to be opaque — but it does not have to be
/// decorated as well.
struct OnboardingCanvas: View {
    var body: some View {
        Color(nsColor: .windowBackgroundColor)
    }
}

// MARK: - Taste

/// A drawn key, used wherever a shortcut is spelled out.
struct KeyCap: View {
    let label: String
    var size: CGFloat = 11

    var body: some View {
        Text(label)
            .font(.system(size: size, weight: .medium, design: .rounded))
            .foregroundStyle(.secondary)
            .frame(minWidth: size + 11, minHeight: size + 9)
            .padding(.horizontal, 4)
            .background {
                RoundedRectangle(cornerRadius: 5, style: .continuous)
                    .fill(OnboardingStyle.surface)
            }
            .overlay {
                RoundedRectangle(cornerRadius: 5, style: .continuous)
                    .strokeBorder(OnboardingStyle.hairline, lineWidth: 1)
            }
    }
}

/// A shortcut and what it does — `⌃ ⌘ V   quick search`.
struct ShortcutLine: View {
    let keys: [String]
    let caption: String

    var body: some View {
        HStack(spacing: 10) {
            HStack(spacing: 3) {
                ForEach(Array(keys.enumerated()), id: \.offset) { _, key in
                    KeyCap(label: key)
                }
            }
            .frame(width: 92, alignment: .leading)

            Text(caption)
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Butoane

/// The button that carries the guide forward. The only filled accent surface
/// in the window — which is what makes it read as the thing to press.
struct OnboardingPrimaryStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 13, weight: .medium))
            .foregroundStyle(.white)
            .padding(.horizontal, 16)
            .frame(height: 28)
            .background {
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(Color.accentColor.opacity(configuration.isPressed ? 0.8 : 1))
            }
            .contentShape(Rectangle())
    }
}

/// The quiet button: Back, Skip. Unfilled, so it never competes with the primary one.
struct OnboardingQuietStyle: ButtonStyle {
    var prominent = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 13, weight: prominent ? .medium : .regular))
            .foregroundStyle(prominent ? Color.primary : Color.secondary)
            .padding(.horizontal, prominent ? 14 : 8)
            .frame(height: 28)
            .background {
                if prominent {
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(OnboardingStyle.surface)
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .strokeBorder(OnboardingStyle.hairline, lineWidth: 1)
                }
            }
            .opacity(configuration.isPressed ? 0.55 : 1)
            .contentShape(Rectangle())
    }
}

// MARK: - Progres

/// One dot per step, grey apart from the current one — the dots say where you
/// are, they do not ask for attention.
struct StepDots: View {
    let steps: [OnboardingStep]
    let current: OnboardingStep
    var onSelect: (OnboardingStep) -> Void

    var body: some View {
        HStack(spacing: 5) {
            ForEach(steps) { step in
                Circle()
                    .fill(step == current ? Color.primary.opacity(0.55) : Color.primary.opacity(0.15))
                    .frame(width: 5, height: 5)
                    .contentShape(Circle().inset(by: -6))
                    .onTapGesture { onSelect(step) }
            }
        }
        .animation(.easeOut(duration: 0.2), value: current)
    }
}

// MARK: - Layout

/// The fixed-height area the illustrations sit in.
///
/// Fixed on purpose: the mockups differ in height, and letting the area resize
/// would make the title and buttons below jump on every step.
struct HeroStage<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        ZStack {
            content
        }
        .frame(maxWidth: .infinity)
        .frame(height: Theme.onboardingHeroHeight)
    }
}

/// The shared frame of the mockups: card backing, hairline border, matching
/// corner. Every illustration uses it, so they read as one family rather than
/// seven separate drawings.
struct MockChrome: ViewModifier {
    var cornerRadius: CGFloat = 10

    func body(content: Content) -> some View {
        content
            .background {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(Color(nsColor: .controlBackgroundColor))
            }
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(OnboardingStyle.hairline, lineWidth: 1)
            }
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .shadow(color: .black.opacity(0.12), radius: 12, y: 4)
    }
}

extension View {
    func mockChrome(cornerRadius: CGFloat = 10) -> some View {
        modifier(MockChrome(cornerRadius: cornerRadius))
    }
}
