import AppKit
import Carbon.HIToolbox

/// Global shortcuts, live from any application.
///
/// Carbon's `RegisterEventHotKey` rather than an event tap: it is the only route
/// that doesn't demand Accessibility permission merely to *listen* for keys.
/// That permission stays reserved for pasting.
final class HotKeyCenter {
    static let shared = HotKeyCenter()

    /// Which shortcut fired, keyed by the id handed out at registration.
    private var handlers: [UInt32: () -> Void] = [:]
    private var registrations: [UInt32: EventHotKeyRef] = [:]
    private var nextID: UInt32 = 1
    private var handlerInstalled = false

    private init() {}

    struct Shortcut {
        var keyCode: UInt32
        var modifiers: UInt32

        static let controlCommand = UInt32(controlKey | cmdKey)

        static func controlCommand(_ keyCode: UInt32) -> Shortcut {
            Shortcut(keyCode: keyCode, modifiers: controlCommand)
        }

        /// Key codes, layout-independent, for the keys we bind.
        static let v: UInt32 = 0x09
        static let n: UInt32 = 0x2D
        static let l: UInt32 = 0x25
        static let digits: [UInt32] = [0x1D, 0x12, 0x13, 0x14, 0x15, 0x17, 0x16, 0x1A, 0x1C, 0x19]
    }

    @discardableResult
    func register(_ shortcut: Shortcut, action: @escaping () -> Void) -> UInt32? {
        installHandlerIfNeeded()

        let id = nextID
        nextID += 1

        var hotKeyRef: EventHotKeyRef?
        let hotKeyID = EventHotKeyID(signature: OSType(0x6950_7374), id: id) // 'iPst'
        let status = RegisterEventHotKey(
            shortcut.keyCode,
            shortcut.modifiers,
            hotKeyID,
            GetEventDispatcherTarget(),
            0,
            &hotKeyRef
        )

        guard status == noErr, let hotKeyRef else {
            NSLog("iPaste: could not register shortcut (code \(shortcut.keyCode)), status \(status)")
            return nil
        }

        handlers[id] = action
        registrations[id] = hotKeyRef
        return id
    }

    func unregister(_ id: UInt32) {
        if let ref = registrations[id] { UnregisterEventHotKey(ref) }
        registrations[id] = nil
        handlers[id] = nil
    }

    func unregisterAll() {
        registrations.keys.forEach(unregister)
    }

    fileprivate func fire(id: UInt32) {
        handlers[id]?()
    }

    private func installHandlerIfNeeded() {
        guard !handlerInstalled else { return }
        handlerInstalled = true

        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )

        InstallEventHandler(
            GetEventDispatcherTarget(),
            hotKeyEventHandler,
            1,
            &eventType,
            nil,
            nil
        )
    }
}

/// Carbon's callback must be a C function, so it cannot capture context — which
/// is why it routes through the singleton.
private let hotKeyEventHandler: EventHandlerUPP = { _, event, _ -> OSStatus in
    var hotKeyID = EventHotKeyID()
    let status = GetEventParameter(
        event,
        EventParamName(kEventParamDirectObject),
        EventParamType(typeEventHotKeyID),
        nil,
        MemoryLayout<EventHotKeyID>.size,
        nil,
        &hotKeyID
    )
    guard status == noErr else { return status }

    let id = hotKeyID.id
    DispatchQueue.main.async {
        HotKeyCenter.shared.fire(id: id)
    }
    return noErr
}
