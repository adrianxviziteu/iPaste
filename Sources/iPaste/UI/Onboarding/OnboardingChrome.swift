import SwiftUI

// MARK: - Palette

/// Valorile comune ale ghidului.
///
/// The illustrations are mockups of the real windows, drawn from three greys and
/// a single accent. Color that says nothing is left out: in a guide, every
/// colored patch that does not mark something is noise.
enum OnboardingStyle {
    static let accent = Color(red: 0.16, green: 0.43, blue: 1.0)
    static let canvas = Color(red: 0.018, green: 0.022, blue: 0.032)
    /// A mockup surface — a card, a panel, a row.
    static let surface = Color.white.opacity(0.055)
    /// The same surface, one step raised.
    static let raised = Color.white.opacity(0.09)
    /// The outline, as thin as the display allows.
    static let hairline = Color.white.opacity(0.11)
}

/// The window backdrop: the system window color, nothing more. The window is
/// borderless, so the backdrop has to be opaque — but it does not have to be
/// decorated as well.
struct OnboardingCanvas: View {
    var body: some View {
        ZStack {
            OnboardingStyle.canvas
            RadialGradient(
                colors: [OnboardingStyle.accent.opacity(0.13), .clear],
                center: .top,
                startRadius: 0,
                endRadius: 360
            )
            LinearGradient(
                colors: [.white.opacity(0.025), .clear],
                startPoint: .top,
                endPoint: .center
            )
        }
    }
}

/// A compact product bar shaped like the closed notch. It anchors every step
/// to the place where iPaste actually lives.
struct OnboardingNotchBar: View {
    let step: OnboardingStep

    var body: some View {
        HStack(spacing: 9) {
            ZStack {
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .fill(OnboardingStyle.accent)
                Image(systemName: "doc.on.clipboard.fill")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.white)
            }
            .frame(width: 28, height: 28)
            .shadow(color: OnboardingStyle.accent.opacity(0.35), radius: 9)

            Text("iPaste")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.white)

            Spacer(minLength: 18)

            Text("NOTCH CLIPBOARD")
                .font(.system(size: 7, weight: .bold))
                .tracking(1.2)
                .foregroundStyle(.white.opacity(0.35))

            Text("\(step.rawValue + 1)/\(OnboardingStep.allCases.count)")
                .font(.system(size: 9, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.5))
                .padding(.horizontal, 8)
                .frame(height: 22)
                .background(Color.white.opacity(0.08), in: Capsule())
        }
        .padding(.horizontal, 10)
        .frame(width: 330, height: 46)
        .background(Color.black, in: BottomRoundedRectangle(radius: 15))
        .overlay {
            BottomRoundedRectangle(radius: 15)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.55), radius: 20, y: 10)
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
            .foregroundStyle(.white.opacity(0.64))
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
                .foregroundStyle(.white.opacity(0.5))
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
            .padding(.horizontal, 20)
            .frame(height: 36)
            .background {
                RoundedRectangle(cornerRadius: 11, style: .continuous)
                    .fill(OnboardingStyle.accent.opacity(configuration.isPressed ? 0.78 : 1))
            }
            .shadow(color: OnboardingStyle.accent.opacity(0.24), radius: 12, y: 5)
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .contentShape(Rectangle())
    }
}

/// The quiet button: Back, Skip. Unfilled, so it never competes with the primary one.
struct OnboardingQuietStyle: ButtonStyle {
    var prominent = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 13, weight: prominent ? .medium : .regular))
            .foregroundStyle(prominent ? Color.white : Color.white.opacity(0.48))
            .padding(.horizontal, prominent ? 14 : 8)
            .frame(height: 36)
            .background {
                if prominent {
                    RoundedRectangle(cornerRadius: 11, style: .continuous)
                        .fill(OnboardingStyle.surface)
                    RoundedRectangle(cornerRadius: 11, style: .continuous)
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
                Capsule()
                    .fill(step == current ? OnboardingStyle.accent : Color.white.opacity(0.15))
                    .frame(width: step == current ? 18 : 5, height: 5)
                    .contentShape(Capsule().inset(by: -6))
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
    var cornerRadius: CGFloat = 14

    func body(content: Content) -> some View {
        content
            .background {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(Color.black.opacity(0.72))
            }
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(OnboardingStyle.hairline, lineWidth: 1)
            }
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .shadow(color: .black.opacity(0.42), radius: 20, y: 10)
    }
}

extension View {
    func mockChrome(cornerRadius: CGFloat = 10) -> some View {
        modifier(MockChrome(cornerRadius: cornerRadius))
    }
}
