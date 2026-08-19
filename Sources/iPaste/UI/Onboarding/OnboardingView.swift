import AppKit
import SwiftUI

/// The first-run guide. Assembles the pieces from `OnboardingChrome` and the
/// illustrations from `OnboardingHeroes` into one screen per `OnboardingStep`.
///
/// The settings that matter — shelf mode, permission, launch at login — are
/// handled right here, not in a preferences window the user would have to find.
struct OnboardingView: View {
    @EnvironmentObject private var app: AppState

    @State private var step: OnboardingStep = .welcome
    /// Re-read while the permission step is on screen, so what is shown here is
    /// whatever the user just did in System Settings.
    @State private var hasPermission = false

    /// Optional on purpose: the guide is built both with and without a completion
    /// closure, so accept either and fall back to the coordinator's own method.
    var onFinish: (() -> Void)?

    var body: some View {
        ZStack {
            OnboardingCanvas()

            VStack(spacing: 0) {
                OnboardingNotchBar(step: step)
                    .padding(.top, 0)

                HeroStage { hero }
                    .padding(.top, 20)

                VStack(spacing: 11) {
                    Text(step.title)
                        .font(.system(size: 27, weight: .bold))
                        .tracking(-0.7)
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)

                    Text(step.subtitle)
                        .font(.system(size: 13, weight: .regular))
                        .foregroundStyle(.white.opacity(0.5))
                        .multilineTextAlignment(.center)
                        .lineSpacing(3)
                        .frame(maxWidth: 470)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.top, 18)
                .padding(.horizontal, 40)

                Spacer(minLength: 12)

                footer
            }
            // Each step is its own view, so the pair slides and fades as one unit.
            .id(step)
            .transition(.opacity.combined(with: .offset(y: 10)))
        }
        .frame(width: Theme.onboardingSize.width, height: Theme.onboardingSize.height)
        .clipShape(RoundedRectangle(cornerRadius: Theme.onboardingCornerRadius, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: Theme.onboardingCornerRadius, style: .continuous)
                .strokeBorder(Color.white.opacity(0.1), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.6), radius: 40, y: 18)
        .environment(\.colorScheme, .dark)
        .tint(OnboardingStyle.accent)
        .animation(.spring(response: 0.38, dampingFraction: 0.86), value: step)
        .onAppear { hasPermission = app.paster.hasAccessibilityPermission(prompt: false) }
        // The window is borderless and the permission step blocks the way forward,
        // so Escape is the only way out for someone who cannot grant access at all.
        // It dismisses the guide without advancing through it.
        .onExitCommand { finish() }
    }

    /// Closing the guide: use the closure passed in if there is one, otherwise
    /// the coordinator own method.
    /// The permission step is the one place the guide will not move past until
    /// it has what it needs. Everything after it — pasting, the shortcuts, the
    /// shelf — is inert without Accessibility access, so continuing would only
    /// promise things that would not work.
    private var isBlocked: Bool {
        step == .permission && !hasPermission
    }

    private func finish() {
        if let onFinish { onFinish() } else { app.finishOnboarding() }
    }

    // MARK: - Subsol

    private var footer: some View {
        VStack(spacing: 16) {
            controls

            HStack {
                if let previous = step.previous {
                    Button("Back") { step = previous }
                        .buttonStyle(OnboardingQuietStyle())
                } else {
                    Button("Skip") { finish() }
                        .buttonStyle(OnboardingQuietStyle())
                }

                Spacer()

                StepDots(steps: OnboardingStep.allCases, current: step) { step = $0 }

                Spacer()

                Button(step.primaryLabel) {
                    if let next = step.next { step = next } else { finish() }
                }
                .buttonStyle(OnboardingPrimaryStyle())
                .disabled(isBlocked)
                .opacity(isBlocked ? 0.4 : 1)
                .help(isBlocked ? "Grant Accessibility access to continue" : "")
            }
            .padding(.horizontal, 30)
            .padding(.bottom, 22)
        }
        .padding(.top, 12)
        .background {
            LinearGradient(
                colors: [Color.white.opacity(0.035), .clear],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }

    /// The steps that ask something of the user rather than just telling them
    /// something. The height is fixed, or the footer would jump between steps.
    @ViewBuilder
    private var controls: some View {
        ZStack {
            switch step {
            case .shelf:
                ShelfModePicker()
            case .permission:
                AccessibilityControl(granted: $hasPermission) {
                    app.requestAccessibilityPermission()
                }
            case .ready:
                ReadySummary()
            default:
                EmptyView()
            }
        }
        .padding(.horizontal, 30)
        .frame(height: 100)
    }

    // MARK: - Illustrations

    @ViewBuilder
    private var hero: some View {
        switch step {
        case .welcome:    WelcomeHero()
        case .capture:    CaptureHero()
        case .search:     SearchHero()
        case .shelf:      ShelfHero()
        case .library:    LibraryHero()
        case .permission: PermissionHero(granted: hasPermission)
        case .ready:      ReadyHero()
        }
    }
}
