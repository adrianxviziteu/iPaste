import SwiftUI

/// The app's visual constants, in one place.
enum Theme {
    static let cornerRadius: CGFloat = 14
    static let cardRadius: CGFloat = 10
    static let rowHeight: CGFloat = 52

    static let panelWidth: CGFloat = 680
    static let panelHeight: CGFloat = 460

    /// The shelf hangs from the top edge, so it rounds only downward.
    static let shelfCornerRadius: CGFloat = 28
    static let shelfWidth: CGFloat = 900
    static let shelfHeight: CGFloat = 252
    static let shelfExpandedHeight: CGFloat = 492
    static let shelfCardSize = CGSize(width: 148, height: 104)
    /// Vertical slack around a card so hover growth and the entrance slide are
    /// not clipped by the scroll view that holds them.
    static let shelfCardBreathingRoom: CGFloat = 6
    static var shelfCardsRowHeight: CGFloat { shelfCardSize.height + shelfCardBreathingRoom * 2 + 18 }

    /// The capture pill. Narrow enough to read as a notch, not as a banner.
    static let flashSize = CGSize(width: 248, height: 42)
    static let flashCornerRadius: CGFloat = 16

    /// The first-run guide, in its own window.
    /// Taller than it looks like it needs: a row of controls sits under the text
    /// (shelf mode, permission, launch at login) and would push the footer off.
    static let onboardingSize = CGSize(width: 620, height: 610)
    /// Fixed height for the illustrations: otherwise title and buttons jump every step.
    static let onboardingHeroHeight: CGFloat = 220
    static let onboardingCornerRadius: CGFloat = 20

    /// A translucent backing, so a panel sits over content without hiding it.
    struct PanelBackground: View {
        var body: some View {
            RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous)
                        .strokeBorder(Color.primary.opacity(0.08), lineWidth: 1)
                )
        }
    }
}

extension Color {
    /// The red of the close button on the shelf. Warmer and lighter than the
    /// system red, which turns muddy against the shelf's black.
    static let closeRed = Color(red: 1.0, green: 0.42, blue: 0.40)
}

extension View {
    /// Rounded corners plus panel backing, shared by every floating window.
    func panelChrome() -> some View {
        background(Theme.PanelBackground())
            .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous))
    }
}
