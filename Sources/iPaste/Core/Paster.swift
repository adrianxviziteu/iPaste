import AppKit
import ApplicationServices

/// Writes a clip back to the pasteboard and, optionally, pastes it into the app
/// the user came from.
///
/// The paste itself is a synthetic ⌘V: macOS has no public API for "insert this
/// into the frontmost app", so every clipboard manager does exactly this. It
/// requires Accessibility permission.
@MainActor
final class Paster {
    private let store: ClipStore
    private unowned let monitor: ClipboardMonitor

    /// The last active app that wasn't us — where a paste is aimed.
    private(set) var previousApp: NSRunningApplication?

    init(store: ClipStore, monitor: ClipboardMonitor) {
        self.store = store
        self.monitor = monitor
        observeFrontmostApp()
    }

    // MARK: - Pasteboard

    /// Puts the clip on the clipboard without pasting anything.
    func copyToPasteboard(_ clip: Clip) {
        monitor.suppressNextChange()
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()

        switch clip.kind {
        case .image:
            if let url = store.imageURL(for: clip), let image = NSImage(contentsOf: url) {
                pasteboard.writeObjects([image])
            }
        case .file:
            let urls = clip.text
                .split(separator: "\n")
                .map { URL(fileURLWithPath: String($0)) as NSURL }
            if urls.isEmpty {
                pasteboard.setString(clip.text, forType: .string)
            } else {
                pasteboard.writeObjects(urls)
            }
        default:
            pasteboard.setString(clip.text, forType: .string)
        }
    }

    /// Copies, hands focus back to the previous app, then sends ⌘V.
    func paste(_ clip: Clip) {
        copyToPasteboard(clip)

        guard hasAccessibilityPermission(prompt: true) else {
            // Without permission the content is still on the clipboard — the user can paste it.
            NSLog("iPaste: no Accessibility permission, copied to clipboard only")
            return
        }

        let target = previousApp
        target?.activate()

        // An app that just got focus needs a few tens of ms before it accepts events.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
            Self.sendCommandV()
        }
    }

    /// Copies the current selection in the app the user came from. The monitor
    /// is told to ignore the resulting pasteboard notification; AppState then
    /// imports it explicitly as a Text Capture action.
    func copySelection(completion: @escaping @MainActor () -> Void) {
        guard hasAccessibilityPermission(prompt: true) else { return }
        monitor.prepareForExplicitCapture()
        previousApp?.activate()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
            Self.sendCommandC()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.14) {
                completion()
            }
        }
    }

    // MARK: - Permissions

    @discardableResult
    func hasAccessibilityPermission(prompt: Bool) -> Bool {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: prompt]
        return AXIsProcessTrustedWithOptions(options as CFDictionary)
    }

    // MARK: - Synthetic event

    private static func sendCommandV() {
        guard let source = CGEventSource(stateID: .combinedSessionState) else { return }
        // Keep a Command the user is physically holding from polluting the event.
        source.setLocalEventsFilterDuringSuppressionState(
            [.permitLocalMouseEvents, .permitSystemDefinedEvents],
            state: .eventSuppressionStateSuppressionInterval
        )

        let vKeyCode: CGKeyCode = 0x09
        let keyDown = CGEvent(keyboardEventSource: source, virtualKey: vKeyCode, keyDown: true)
        let keyUp = CGEvent(keyboardEventSource: source, virtualKey: vKeyCode, keyDown: false)
        keyDown?.flags = .maskCommand
        keyUp?.flags = .maskCommand

        keyDown?.post(tap: .cgAnnotatedSessionEventTap)
        keyUp?.post(tap: .cgAnnotatedSessionEventTap)
    }

    private static func sendCommandC() {
        guard let source = CGEventSource(stateID: .combinedSessionState) else { return }
        source.setLocalEventsFilterDuringSuppressionState(
            [.permitLocalMouseEvents, .permitSystemDefinedEvents],
            state: .eventSuppressionStateSuppressionInterval
        )

        let cKeyCode: CGKeyCode = 0x08
        let keyDown = CGEvent(keyboardEventSource: source, virtualKey: cKeyCode, keyDown: true)
        let keyUp = CGEvent(keyboardEventSource: source, virtualKey: cKeyCode, keyDown: false)
        keyDown?.flags = .maskCommand
        keyUp?.flags = .maskCommand
        keyDown?.post(tap: .cgAnnotatedSessionEventTap)
        keyUp?.post(tap: .cgAnnotatedSessionEventTap)
    }

    /// Tracks who is frontmost, so we know where to paste once our own window opens.
    private func observeFrontmostApp() {
        NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication,
                  app.bundleIdentifier != Bundle.main.bundleIdentifier,
                  app.processIdentifier != ProcessInfo.processInfo.processIdentifier
            else { return }
            MainActor.assumeIsolated { self?.previousApp = app }
        }
    }
}
