import AppKit

/// Detects when the cursor reaches the top edge of the screen, and when it
/// leaves the shelf again.
///
/// Mouse-move monitors rather than an invisible window with a tracking area: a
/// window that receives events would swallow clicks on the menu bar, and one
/// that ignores them would never see the hover at all.
@MainActor
final class ShelfHoverMonitor {
    /// How tall the sensitive strip along the top edge is.
    // A few pixels are lost to the menu bar/notch hit area. A 14 px band makes
    // hover reliable without making the top edge feel accidentally sensitive.
    private let triggerHeight: CGFloat = 14
    /// Minimum width of that strip on screens without a notch.
    private let minimumTriggerWidth: CGFloat = 240

    private var globalMonitor: Any?
    private var localMonitor: Any?
    private var hideWorkItem: DispatchWorkItem?
    private var dragTriggerPanels: [NSPanel] = []

    /// The visible shelf's frame, so we can tell when the cursor has left it.
    var shelfFrame: () -> NSRect? = { nil }
    var hideDelay: TimeInterval = 0.45

    var onEnterTrigger: (() -> Void)?
    var onEnterDropTarget: (() -> Void)?
    var onLeaveDropTarget: (() -> Void)?
    var onLeaveShelf: (() -> Void)?
    var onDrop: ((NSPasteboard) -> Bool)?

    var isRunning: Bool { globalMonitor != nil }

    private let pointerEventMask: NSEvent.EventTypeMask = [
        .mouseMoved,
        .leftMouseDragged,
        .rightMouseDragged,
        .leftMouseUp,
        .rightMouseUp
    ]

    func start() {
        guard !isRunning else { return }
        // Global: the cursor is over other apps. Local: it is over our own windows.
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: pointerEventMask) { [weak self] event in
            MainActor.assumeIsolated { self?.handlePointerEvent(event) }
        }
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: pointerEventMask) { [weak self] event in
            MainActor.assumeIsolated { self?.handlePointerEvent(event) }
            return event
        }
        installDragTriggerPanels()
    }

    func stop() {
        [globalMonitor, localMonitor].forEach { monitor in
            if let monitor { NSEvent.removeMonitor(monitor) }
        }
        globalMonitor = nil
        localMonitor = nil
        dragTriggerPanels.forEach { $0.orderOut(nil) }
        dragTriggerPanels.removeAll()
        cancelPendingHide()
    }

    /// Keeps only the drop targets alive. A deliberate drag is allowed to open
    /// the shelf even when ordinary hover opening is disabled.
    func startDragDetection() {
        installDragTriggerPanels()
    }

    /// Global mouse monitors are not reliable during every kind of drag session
    /// (especially Finder and browser drags). These tiny transparent panels let
    /// AppKit deliver `draggingEntered` directly while leaving the menu bar free.
    private func installDragTriggerPanels() {
        dragTriggerPanels.forEach { $0.orderOut(nil) }
        dragTriggerPanels.removeAll()

        for screen in NSScreen.screens {
            let notchWidth = max(NotchMetrics.notchWidth(for: screen), minimumTriggerWidth)
            let frame = NSRect(
                x: screen.frame.midX - notchWidth / 2,
                y: screen.frame.maxY - 10,
                width: notchWidth,
                height: 10
            )
            let panel = NSPanel(
                contentRect: frame,
                styleMask: [.borderless, .nonactivatingPanel],
                backing: .buffered,
                defer: false
            )
            panel.level = NSWindow.Level(rawValue: NSWindow.Level.statusBar.rawValue + 1)
            panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
            panel.backgroundColor = .clear
            panel.isOpaque = false
            panel.hasShadow = false
            panel.ignoresMouseEvents = false
            panel.hidesOnDeactivate = false

            let view = DragTriggerView { [weak self] in
                self?.cancelPendingHide()
                self?.onEnterDropTarget?()
            } exited: { [weak self] in
                self?.onLeaveDropTarget?()
            } dropped: { [weak self] pasteboard in
                self?.onDrop?(pasteboard) ?? false
            }
            panel.contentView = view
            panel.orderFrontRegardless()
            dragTriggerPanels.append(panel)
        }
    }

    func cancelPendingHide() {
        hideWorkItem?.cancel()
        hideWorkItem = nil
    }

    // MARK: - Hover logic

    private func handlePointerEvent(_ event: NSEvent) {
        let location = NSEvent.mouseLocation
        let isDragging = event.type == .leftMouseDragged || event.type == .rightMouseDragged

        if let frame = shelfFrame() {
            // Do not retract the shelf under an item that is still being held.
            // The next mouse-up decides whether it should close.
            if isDragging {
                cancelPendingHide()
                return
            }

            // The shelf is open: all that matters is whether we left it.
            if frame.insetBy(dx: -4, dy: -4).contains(location) {
                cancelPendingHide()
            } else {
                scheduleHide()
            }
            return
        }

        if isInTriggerZone(location) {
            cancelPendingHide()
            onEnterTrigger?()
        }
    }

    private func isInTriggerZone(_ location: NSPoint) -> Bool {
        guard let screen = NSScreen.screens.first(where: { $0.frame.contains(location) })
                ?? NSScreen.main
        else { return false }

        guard location.y >= screen.frame.maxY - triggerHeight else { return false }

        // On notched screens the hot zone is the notch itself; otherwise a centered strip.
        let width = max(NotchMetrics.notchWidth(for: screen), minimumTriggerWidth)
        let horizontalRange = (screen.frame.midX - width / 2)...(screen.frame.midX + width / 2)
        return horizontalRange.contains(location.x)
    }

    private func scheduleHide() {
        guard hideWorkItem == nil else { return }
        let item = DispatchWorkItem { [weak self] in
            self?.hideWorkItem = nil
            self?.onLeaveShelf?()
        }
        hideWorkItem = item
        DispatchQueue.main.asyncAfter(deadline: .now() + hideDelay, execute: item)
    }
}

/// An invisible AppKit drag destination positioned over the notch trigger zone.
private final class DragTriggerView: NSView {
    private let entered: () -> Void
    private let exited: () -> Void
    private let dropped: (NSPasteboard) -> Bool

    init(
        entered: @escaping () -> Void,
        exited: @escaping () -> Void,
        dropped: @escaping (NSPasteboard) -> Bool
    ) {
        self.entered = entered
        self.exited = exited
        self.dropped = dropped
        super.init(frame: .zero)
        registerForDraggedTypes([
            .fileURL,
            .URL,
            .string,
            .png,
            .tiff
        ])
    }

    required init?(coder: NSCoder) {
        return nil
    }

    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        entered()
        return .copy
    }

    override func draggingUpdated(_ sender: NSDraggingInfo) -> NSDragOperation {
        entered()
        return .copy
    }

    override func draggingExited(_ sender: NSDraggingInfo?) {
        exited()
    }

    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        return dropped(sender.draggingPasteboard)
    }
}
