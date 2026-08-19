import AppKit
import SwiftUI

/// A chromeless window that floats above everything and can take the keyboard.
///
/// A plain `NSPanel` refuses to become the key window while borderless, which is
/// why `canBecomeKey` is overridden — without it the search field never sees a
/// single keystroke.
final class FloatingPanel: NSPanel {
    /// Only the initializer is generic: the concrete content type is lost anyway
    /// after modifiers like `.environmentObject`, and the class never needs it.
    init<Content: View>(contentRect: NSRect, content: () -> Content) {
        super.init(
            contentRect: contentRect,
            styleMask: [.nonactivatingPanel, .fullSizeContentView, .borderless],
            backing: .buffered,
            defer: false
        )

        isFloatingPanel = true
        level = .statusBar
        // Stays visible over fullscreen apps and across every desktop.
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        titleVisibility = .hidden
        titlebarAppearsTransparent = true
        isMovableByWindowBackground = false
        hidesOnDeactivate = false
        isOpaque = false
        backgroundColor = .clear
        hasShadow = true
        animationBehavior = .utilityWindow

        contentView = NSHostingView(rootView: content())
    }

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }

    /// Escape closes the panel, wherever focus happens to be inside it.
    override func cancelOperation(_ sender: Any?) {
        orderOut(nil)
    }

    func show(centeredOn screen: NSScreen? = nil) {
        positionCentered(on: screen ?? NSScreen.main)
        NSApp.activate(ignoringOtherApps: true)
        makeKeyAndOrderFront(nil)
    }

    private func positionCentered(on screen: NSScreen?) {
        guard let screen else { return }
        let visible = screen.visibleFrame
        let size = frame.size
        // A little above true center — dead center reads as too low.
        let origin = NSPoint(
            x: visible.midX - size.width / 2,
            y: visible.midY - size.height / 2 + visible.height * 0.08
        )
        setFrameOrigin(origin)
    }
}
