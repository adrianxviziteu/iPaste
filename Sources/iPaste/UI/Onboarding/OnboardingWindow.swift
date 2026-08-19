import AppKit
import SwiftUI

/// The window the guide lives in: borderless, so the rounded canvas inside is
/// the whole visible shape.
///
/// Unlike `FloatingPanel`, this one activates the app and takes focus — it is a
/// window the user is meant to work in, not something hovering beside their work.
/// It floats anyway, so it stays visible while they're over in System Settings
/// granting Accessibility.
final class OnboardingWindow: NSWindow {
    init<Content: View>(content: () -> Content) {
        super.init(
            contentRect: NSRect(origin: .zero, size: Theme.onboardingSize),
            styleMask: [.borderless, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        level = .floating
        collectionBehavior = [.moveToActiveSpace, .fullScreenAuxiliary]
        isOpaque = false
        backgroundColor = .clear
        hasShadow = true
        // No title bar to grab, so the whole background is the handle.
        isMovableByWindowBackground = true
        animationBehavior = .documentWindow

        contentView = NSHostingView(rootView: content())
    }

    /// Borderless windows refuse focus by default; without this the guide would
    /// never see a key press.
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }

    func showCentered() {
        centerOnScreen()
        NSApp.activate(ignoringOtherApps: true)
        makeKeyAndOrderFront(nil)
    }

    private func centerOnScreen() {
        guard let visible = (NSScreen.main ?? NSScreen.screens.first)?.visibleFrame else { return }
        let size = frame.size
        setFrameOrigin(NSPoint(
            x: visible.midX - size.width / 2,
            // Slightly above the true center — dead center reads as too low.
            y: visible.midY - size.height / 2 + visible.height * 0.06
        ))
    }
}
