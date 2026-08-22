import AppKit
import Combine
import QuartzCore
import SwiftUI
import UserNotifications

/// The app's coordinator: ties capture, history, pasting and windows together.
@MainActor
final class AppState: ObservableObject {
    /// A single instance: the SwiftUI scene and `AppDelegate` need the same state,
    /// and startup has to run from the delegate rather than a scene's `onChange`.
    static let shared = AppState()

    let store: ClipStore
    let monitor: ClipboardMonitor
    let paster: Paster
    let preferences: Preferences
    let temporaryShare = TemporaryShareService()

    private let hoverMonitor = ShelfHoverMonitor()
    private lazy var snippetMonitor = SnippetExpansionMonitor(store: store, paster: paster)
    private var orderOutWorkItem: DispatchWorkItem?
    private var flashPanel: FloatingPanel?
    private var flashHideWorkItem: DispatchWorkItem?
    private var flashOrderOutWorkItem: DispatchWorkItem?
    private var confirmationWorkItem: DispatchWorkItem?
    private var modeObserver: AnyCancellable?
    private var retentionObserver: AnyCancellable?
    private var retentionTimer: Timer?
    private var appActivationObserver: NSObjectProtocol?
    private var reminderPickerWindow: NSWindow?
    private var requestedNotificationPermission = false

    @Published var isShelfVisible = false
    @Published var shelfInspectorClipID: UUID?
    @Published var shelfReminderClipID: UUID?
    /// True while an external item is being dragged over the notch shelf.
    @Published var isDropTargeted = false
    /// The clip the capture pill is currently announcing; nil while it is away.
    @Published var capturedFlash: Clip?
    /// What the pill says it did — the same pill reports a capture, a copy or a paste.
    @Published var flashLabel = "Copied"
    /// The card that should show an in-place confirmation right now.
    @Published var confirmedClipID: UUID?
    @Published var lastCapturedKind: ClipKind?

    private var quickSearchPanel: FloatingPanel?
    private var shelfPanel: FloatingPanel?
    private var onboardingWindow: OnboardingWindow?
    private var settingsWindow: NSWindow?
    private var quickNotesWindow: NSWindow?
    private var libraryWindow: NSWindow?
    private var shareWindow: NSWindow?

    init() {
        let preferences = Preferences()
        self.preferences = preferences
        let store = ClipStore()
        let monitor = ClipboardMonitor(store: store, preferences: preferences)
        self.store = store
        self.monitor = monitor
        self.paster = Paster(store: store, monitor: monitor)
    }

    // MARK: - Startup

    private var didBootstrap = false

    func bootstrap() {
        guard !didBootstrap else { return }
        didBootstrap = true

        monitor.onCapture = { [weak self] clip in
            self?.lastCapturedKind = clip.kind
            self?.flashLabel = "Copied"
            self?.flashCapture(clip)
        }
        monitor.onSensitiveCapture = { [weak self] clip in
            self?.lastCapturedKind = clip.kind
            self?.flashLabel = "Not saved"
            self?.flashCapture(clip)
        }
        configureReminders()
        monitor.start()
        snippetMonitor.start()
        registerHotKeys()
        configureHover()
        applyShelfMode()
        purgeExpiredClips()
        retentionTimer = Timer.scheduledTimer(withTimeInterval: 3_600, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.purgeExpiredClips() }
        }

        modeObserver = preferences.$shelfMode
            .dropFirst()
            .sink { [weak self] mode in self?.applyShelfMode(mode) }
        retentionObserver = preferences.$historyRetentionDays
            .dropFirst()
            .sink { [weak self] _ in self?.purgeExpiredClips() }

        showOnboardingIfNeeded()
    }

    // MARK: - Reminders

    private func configureReminders() {
        scheduleAllReminderNotifications()
        appActivationObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let application = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication,
                  let bundleID = application.bundleIdentifier,
                  bundleID != Bundle.main.bundleIdentifier
            else { return }
            MainActor.assumeIsolated { self?.handleSourceAppReturn(bundleID: bundleID) }
        }
    }

    func remind(_ clip: Clip, in interval: TimeInterval) {
        setReminder(.at(Date().addingTimeInterval(interval)), for: clip)
    }

    func remindTomorrow(_ clip: Clip) {
        let calendar = Calendar.current
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: Date()) ?? Date().addingTimeInterval(86_400)
        let date = calendar.date(bySettingHour: 9, minute: 0, second: 0, of: tomorrow) ?? tomorrow
        setReminder(.at(date), for: clip)
    }

    func remindWhenReturningToSourceApp(_ clip: Clip) {
        guard let bundleID = clip.sourceBundleID,
              canReturnToSourceApp(bundleID: bundleID)
        else { return }
        setReminder(
            .whenReturningToSourceApp(bundleID: bundleID, appName: clip.sourceAppName),
            for: clip
        )
    }

    func removeReminder(from clip: Clip) {
        store.setReminder(nil, for: clip)
        removeScheduledNotification(for: clip)
    }

    func showReminderPicker(for clip: Clip) {
        reminderPickerWindow?.orderOut(nil)
        let window = makeReminderPickerWindow(for: clip)
        reminderPickerWindow = window
        if let panel = window as? FloatingPanel {
            panel.show()
        } else {
            NSApp.activate(ignoringOtherApps: true)
            window.makeKeyAndOrderFront(nil)
        }
    }

    func setReminder(_ reminder: ClipReminder, for clip: Clip) {
        store.setReminder(reminder, for: clip)
        scheduleReminderNotification(for: clip, reminder: reminder)
        requestNotificationPermissionIfNeeded()
    }

    func canReturnToSourceApp(bundleID: String) -> Bool {
        guard bundleID != Bundle.main.bundleIdentifier,
              !bundleID.hasPrefix("com.ipaste."),
              bundleID != "com.apple.screencapture"
        else { return false }
        return true
    }

    private func makeReminderPickerWindow(for clip: Clip) -> NSWindow {
        FloatingPanel(contentRect: NSRect(x: 0, y: 0, width: 430, height: 232)) {
            ReminderPickerView(clip: clip)
                .environmentObject(self)
                .environmentObject(store)
        }
    }

    func closeReminderPicker() {
        reminderPickerWindow?.orderOut(nil)
    }

    private func scheduleAllReminderNotifications() {
        for clip in store.clips {
            guard let reminder = clip.reminder else { continue }
            if reminder.kind == .atDate,
               let fireDate = reminder.fireDate,
               fireDate <= Date() {
                // One-time reminders must not revive every time iPaste opens.
                removeReminder(from: clip)
                continue
            }
            scheduleReminderNotification(for: clip, reminder: reminder)
        }
    }

    private func scheduleReminderNotification(for clip: Clip, reminder: ClipReminder) {
        let identifier = reminderNotificationID(for: clip)
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [identifier])

        guard reminder.kind == .atDate,
              let date = reminder.fireDate,
              date > Date()
        else { return }

        let content = UNMutableNotificationContent()
        content.title = "iPaste Reminder"
        content.body = clip.title.truncated(to: 120)
        content.sound = .default
        content.userInfo = ["clipID": clip.id.uuidString]

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: date.timeIntervalSinceNow, repeats: false)
        center.add(UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)) { error in
            if let error { NSLog("iPaste: could not schedule reminder — \(error.localizedDescription)") }
        }
    }

    private func removeScheduledNotification(for clip: Clip) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: [reminderNotificationID(for: clip)]
        )
    }

    private func reminderNotificationID(for clip: Clip) -> String {
        "clip-reminder-\(clip.id.uuidString)"
    }

    func acknowledgeReminder(clipID: String) {
        guard let id = UUID(uuidString: clipID),
              let clip = store.clips.first(where: { $0.id == id })
        else { return }
        removeReminder(from: clip)
    }

    private func requestNotificationPermissionIfNeeded() {
        guard !requestedNotificationPermission else { return }
        requestedNotificationPermission = true
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, error in
            if let error { NSLog("iPaste: notification permission request failed — \(error.localizedDescription)") }
        }
    }

    private func handleSourceAppReturn(bundleID: String) {
        let matching = store.clips.filter {
            $0.reminder?.kind == .sourceAppReturn && $0.reminder?.sourceBundleID == bundleID
        }
        for clip in matching {
            removeReminder(from: clip)
            deliverReminder(for: clip)
        }
    }

    private func deliverReminder(for clip: Clip) {
        flashLabel = "Reminder"
        flashCapture(clip)

        let content = UNMutableNotificationContent()
        content.title = "iPaste Reminder"
        content.body = clip.title.truncated(to: 120)
        content.sound = .default
        content.userInfo = ["clipID": clip.id.uuidString]
        let request = UNNotificationRequest(
            identifier: "clip-reminder-delivery-\(UUID().uuidString)",
            content: content,
            trigger: UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        )
        UNUserNotificationCenter.current().add(request)
    }

    private func registerHotKeys() {
        // ⌃⌘V — quick search, from anywhere.
        HotKeyCenter.shared.register(.controlCommand(HotKeyCenter.Shortcut.v)) { [weak self] in
            self?.toggleQuickSearch()
        }

        // ⌃⌘N — jot down a note without touching the system clipboard.
        HotKeyCenter.shared.register(.controlCommand(HotKeyCenter.Shortcut.n)) { [weak self] in
            self?.showQuickNotes()
        }

        // ⌃⌘L — open the complete visual clipboard library.
        HotKeyCenter.shared.register(.controlCommand(HotKeyCenter.Shortcut.l)) { [weak self] in
            self?.showLibrary()
        }

        // ⌃⌘0…9 — paste the recent clip at that position directly.
        for (index, keyCode) in HotKeyCenter.Shortcut.digits.enumerated() {
            HotKeyCenter.shared.register(.controlCommand(keyCode)) { [weak self] in
                self?.pasteRecent(at: index)
            }
        }

        // ⌃⌘S — show or hide the top shelf.
        HotKeyCenter.shared.register(.controlCommand(0x01)) { [weak self] in
            self?.toggleShelf()
        }

        // ⌃⌘P pastes the intentionally ordered clipboard stack.
        HotKeyCenter.shared.register(.controlCommand(0x23)) { [weak self] in
            self?.pasteStack()
        }
    }

    // MARK: - Actions

    /// ⌃⌘0 is the most recent clip, ⌃⌘1 the one before it, and so on.
    ///
    /// These always paste, whatever the click preference says: pressing a shortcut
    /// while typing is an unambiguous instruction about where the text should go.
    func pasteRecent(at index: Int) {
        let recent = store.orderedClips
        guard index < recent.count else { return }
        paster.paste(recent[index])
    }

    /// What picking a clip does — click, Enter, or a menu item.
    ///
    /// Routed through one place so the choice is honoured everywhere, instead of
    /// each surface deciding for itself what a click means.
    ///
    /// - Parameter inverted: perform the other action this once, for ⌘-clicking
    ///   or ⌘↩ when the default is not what is wanted right now.
    func activate(_ clip: Clip, inverted: Bool = false) {
        var action = preferences.clickActivation
        if inverted { action = action == .copy ? .paste : .copy }

        switch action {
        case .copy:  copy(clip)
        case .paste: paste(clip)
        }
    }

    func paste(_ clip: Clip) {
        hideQuickSearch()
        paster.paste(clip)
        store.markUsed(clip)
        confirm(clip, saying: "Pasted")
    }

    func copy(_ clip: Clip) {
        hideQuickSearch()
        paster.copyToPasteboard(clip)
        store.markUsed(clip)
        // Copying is silent by nature — the pill is the only sign it worked.
        confirm(clip, saying: "Copied")
    }

    func copyTextVariant(_ text: String, for clip: Clip) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
        monitor.ignoreOwnChanges(through: NSPasteboard.general.changeCount)
        confirm(clip, saying: "Copied")
    }

    func apply(_ action: ClipAction, to clip: Clip) {
        guard let text = action.apply(to: clip.text) else { return }
        copyTextVariant(text, for: clip)
    }

    func pasteStack() {
        let clips = store.stack
        guard !clips.isEmpty else { return }
        hideQuickSearch()
        for (index, clip) in clips.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.38 * Double(index)) { [weak self] in
                guard let self else { return }
                self.paster.paste(clip)
                self.store.markUsed(clip)
            }
        }
        if let first = clips.first { confirm(first, saying: "Pasting \(clips.count) clips") }
    }

    func shareTemporarily(_ clip: Clip) {
        guard clip.kind != .multi else { return }
        if clip.kind == .image,
           let imageURL = store.imageURL(for: clip),
           let data = try? Data(contentsOf: imageURL) {
            temporaryShare.share(data: data, contentType: "image/png")
        } else {
            temporaryShare.share(text: clip.text)
        }
        let window = shareWindow ?? makeShareWindow()
        shareWindow = window
        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
    }

    func stopSharing() {
        temporaryShare.stop()
        shareWindow?.orderOut(nil)
    }

    @discardableResult
    func captureDroppedProviders(_ providers: [NSItemProvider]) -> Bool {
        monitor.captureDroppedProviders(providers)
    }

    // MARK: - Utility tools

    /// Opens the system sampler and stores the selected screen color as a normal
    /// color clip, while also putting its hex value on the clipboard.
    func pickColor() {
        NSColorSampler().show { [weak self] color in
            guard let color, let hex = color.ipasteHexString else { return }
            DispatchQueue.main.async {
                self?.savePickedColor(hex)
            }
        }
    }

    private func savePickedColor(_ hex: String) {
        let clip = Clip(
            kind: .color,
            text: hex,
            sourceAppName: "Color Picker",
            sourceBundleID: "com.ipaste.color-picker",
            fingerprint: ClipboardMonitor.fingerprint(hex),
            byteSize: hex.utf8.count
        )
        let stored = store.insert(clip)
        paster.copyToPasteboard(stored)
        flashLabel = "Color saved"
        flashCapture(stored)
    }

    /// Copies the current selection from the previous app and imports it as a
    /// text clip. A missing selection is ignored rather than duplicating history.
    func captureSelectedText() {
        paster.copySelection { [weak self] in
            guard let self, self.monitor.captureCurrentPasteboard(textOnly: true) else { return }
            self.flashLabel = "Text captured"
        }
    }

    @discardableResult
    func saveQuickNote(_ text: String, copyToClipboard: Bool = false) -> Bool {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }

        let clip = Clip(
            kind: .text,
            text: trimmed,
            sourceAppName: "Quick Notes",
            sourceBundleID: "com.ipaste.quick-notes",
            fingerprint: ClipboardMonitor.fingerprint(trimmed),
            byteSize: trimmed.utf8.count
        )
        let stored = store.insert(clip)
        if copyToClipboard { paster.copyToPasteboard(stored) }
        flashLabel = "Note saved"
        flashCapture(stored)
        return true
    }

    private func purgeExpiredClips() {
        _ = store.removeExpiredClips(olderThanDays: preferences.historyRetentionDays)
        for (bundleID, days) in preferences.retentionDaysByApplication {
            _ = store.removeExpiredClips(olderThanDays: days, sourceBundleID: bundleID)
        }
    }

    /// Confirms an action the user just took.
    ///
    /// Where the confirmation appears depends on where the action happened. With
    /// the shelf open, the pill would land on top of the shelf itself and say
    /// nothing about which card was pressed — so the card confirms in place, and
    /// the pill is left for actions taken with the shelf away.
    private func confirm(_ clip: Clip, saying label: String) {
        flashLabel = label

        guard isShelfVisible else {
            flashCapture(clip)
            return
        }

        confirmedClipID = clip.id
        confirmationWorkItem?.cancel()
        let item = DispatchWorkItem { [weak self] in
            guard self?.confirmedClipID == clip.id else { return }
            self?.confirmedClipID = nil
        }
        confirmationWorkItem = item
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0, execute: item)
    }

    // MARK: - Quick search

    func toggleQuickSearch() {
        if let panel = quickSearchPanel, panel.isVisible {
            hideQuickSearch()
        } else {
            showQuickSearch()
        }
    }

    func showQuickSearch() {
        let panel = quickSearchPanel ?? makeQuickSearchPanel()
        quickSearchPanel = panel
        panel.show()
    }

    func hideQuickSearch() {
        quickSearchPanel?.orderOut(nil)
        // Hand focus back to the app the user came from.
        paster.previousApp?.activate()
    }

    private func makeQuickSearchPanel() -> FloatingPanel {
        FloatingPanel(
            contentRect: NSRect(x: 0, y: 0, width: Theme.panelWidth, height: Theme.panelHeight)
        ) {
            QuickSearchView()
                .environmentObject(self)
                .environmentObject(self.store)
                .environmentObject(self.preferences)
        }
    }

    /// Opens the dedicated settings window. Preferences are deliberately kept
    /// out of the status-item menu so the menu remains a quick action surface.
    func showSettings() {
        let window = settingsWindow ?? makeSettingsWindow()
        settingsWindow = window
        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
    }

    private func makeSettingsWindow() -> NSWindow {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 560, height: 560),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "iPaste Settings"
        window.contentView = NSHostingView(
            rootView: SettingsView()
                .environmentObject(self)
                .environmentObject(self.store)
                .environmentObject(self.preferences)
        )
        window.isReleasedWhenClosed = false
        window.center()
        return window
    }

    func showQuickNotes() {
        let window = quickNotesWindow ?? makeQuickNotesWindow()
        quickNotesWindow = window
        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
    }

    /// Opens the full library window. Keeping one window instance means search,
    /// selection, and the user's last layout survive closing and reopening it.
    func showLibrary() {
        let window = libraryWindow ?? makeLibraryWindow()
        libraryWindow = window
        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
    }

    private func makeLibraryWindow() -> NSWindow {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 1_080, height: 680),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "iPaste Library"
        window.titleVisibility = .visible
        window.contentView = NSHostingView(
            rootView: LibraryView()
                .environmentObject(self)
                .environmentObject(self.store)
                .environmentObject(self.preferences)
        )
        window.isReleasedWhenClosed = false
        window.minSize = NSSize(width: 980, height: 620)
        window.center()
        return window
    }

    private func makeQuickNotesWindow() -> NSWindow {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 520, height: 360),
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Quick Notes"
        window.contentView = NSHostingView(
            rootView: QuickNotesView()
                .environmentObject(self)
                .environmentObject(self.store)
        )
        window.isReleasedWhenClosed = false
        window.minSize = NSSize(width: 420, height: 280)
        window.center()
        return window
    }

    private func makeShareWindow() -> NSWindow {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 330, height: 400),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "Share Clip"
        window.contentView = NSHostingView(rootView: TemporaryShareView(service: temporaryShare).environmentObject(self))
        window.isReleasedWhenClosed = false
        window.center()
        return window
    }

    // MARK: - Capture pill

    /// Announces a fresh capture at the notch for a moment.
    ///
    /// Skipped while the shelf is open: the clip is already appearing there, and
    /// a second confirmation on top of the first is just noise.
    func flashCapture(_ clip: Clip) {
        guard !isShelfVisible else { return }

        let panel = flashPanel ?? makeFlashPanel()
        flashPanel = panel
        positionFlash(panel)
        flashOrderOutWorkItem?.cancel()
        if !panel.isVisible { panel.orderFrontRegardless() }

        capturedFlash = clip

        // Copying several things in a row extends the same pill rather than
        // stacking pills — the last one copied is the one worth showing.
        flashHideWorkItem?.cancel()
        let hide = DispatchWorkItem { [weak self] in self?.dismissFlash() }
        flashHideWorkItem = hide
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.6, execute: hide)
    }

    private func dismissFlash() {
        capturedFlash = nil
        let item = DispatchWorkItem { [weak self] in
            guard let self, self.capturedFlash == nil else { return }
            self.flashPanel?.orderOut(nil)
        }
        flashOrderOutWorkItem = item
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: item)
    }

    private func makeFlashPanel() -> FloatingPanel {
        let panel = FloatingPanel(
            contentRect: NSRect(origin: .zero, size: Theme.flashSize)
        ) {
            CaptureFlashView()
                .environmentObject(self)
                .environmentObject(self.store)
        }
        panel.level = NSWindow.Level(rawValue: NSWindow.Level.statusBar.rawValue + 1)
        panel.hasShadow = false
        // Never steals the keystroke that is probably still being typed elsewhere.
        panel.styleMask.insert(.nonactivatingPanel)
        return panel
    }

    private func positionFlash(_ panel: NSPanel) {
        guard let screen = NSScreen.main else { return }
        panel.setContentSize(Theme.flashSize)
        panel.setFrameOrigin(NSPoint(
            x: screen.frame.midX - Theme.flashSize.width / 2,
            y: screen.frame.maxY - Theme.flashSize.height
        ))
    }

    // MARK: - Top shelf

    private func configureHover() {
        hoverMonitor.hideDelay = preferences.hideDelay
        hoverMonitor.shelfFrame = { [weak self] in
            guard let panel = self?.shelfPanel, panel.isVisible else { return nil }
            return panel.frame
        }
        hoverMonitor.onEnterTrigger = { [weak self] in
            self?.showShelf()
        }
        hoverMonitor.onEnterDropTarget = { [weak self] in
            self?.isDropTargeted = true
            self?.showShelf()
        }
        hoverMonitor.onLeaveDropTarget = { [weak self] in
            self?.isDropTargeted = false
        }
        hoverMonitor.onDrop = { [weak self] pasteboard in
            guard let self else { return false }
            self.isDropTargeted = false
            return self.monitor.captureDroppedPasteboard(pasteboard)
        }
        hoverMonitor.onLeaveShelf = { [weak self] in
            guard self?.preferences.shelfMode == .onHover else { return }
            self?.hideShelf()
        }
    }

    /// Applies the chosen mode: always open, on hover, or never.
    func applyShelfMode(_ mode: ShelfMode? = nil) {
        switch mode ?? preferences.shelfMode {
        case .always:
            hoverMonitor.stop()
            hoverMonitor.startDragDetection()
            showShelf()
        case .onHover:
            hideShelf()
            hoverMonitor.start()
        case .never:
            hoverMonitor.stop()
            hoverMonitor.startDragDetection()
            hideShelf()
        }
    }

    /// ⌃⌘S stays a manual toggle, whatever the mode.
    func toggleShelf() {
        isShelfVisible ? hideShelf() : showShelf()
    }

    func showShelf() {
        let panel = shelfPanel ?? makeShelfPanel()
        let isNew = shelfPanel == nil
        shelfPanel = panel

        hoverMonitor.cancelPendingHide()
        orderOutWorkItem?.cancel()
        orderOutWorkItem = nil

        positionShelf(panel)
        if !panel.isVisible { panel.orderFrontRegardless() }

        if isNew {
            // Leave one draw cycle with the shelf still "up", or SwiftUI has no
            // starting state to animate from and it simply appears, unanimated.
            DispatchQueue.main.async { [weak self] in self?.isShelfVisible = true }
        } else {
            isShelfVisible = true
        }
    }

    func showShelfInspector(for clip: Clip) {
        shelfReminderClipID = nil
        shelfInspectorClipID = clip.id
        resizeShelf(expanded: true)
    }

    func closeShelfInspector() {
        shelfInspectorClipID = nil
        resizeShelf(expanded: false)
    }

    func showShelfReminderPicker(for clip: Clip) {
        shelfInspectorClipID = nil
        shelfReminderClipID = clip.id
        resizeShelf(width: Theme.shelfReminderWidth, height: Theme.shelfReminderHeight)
    }

    /// Returns to the selected clip inspector, so closing the reminder editor
    /// does not throw the user back to the top-level shelf.
    func closeShelfReminderPicker() {
        guard let clipID = shelfReminderClipID else { return }
        shelfReminderClipID = nil
        shelfInspectorClipID = clipID
        resizeShelf(width: Theme.shelfWidth, height: Theme.shelfExpandedHeight)
    }

    func hideShelf() {
        isDropTargeted = false
        shelfInspectorClipID = nil
        shelfReminderClipID = nil
        guard let panel = shelfPanel else {
            isShelfVisible = false
            return
        }
        guard isShelfVisible || panel.isVisible else { return }
        isShelfVisible = false

        // The window leaves only after the content has finished sliding up,
        // otherwise the animation is cut off halfway.
        let item = DispatchWorkItem { [weak self] in
            guard let self, !self.isShelfVisible else { return }
            panel.orderOut(nil)
            self.orderOutWorkItem = nil
        }
        orderOutWorkItem = item
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.34, execute: item)
    }

    /// The final frame: flush against the top edge, centered horizontally.
    /// The window itself never moves — the content does the sliding.
    private func positionShelf(_ panel: NSPanel) {
        guard let screen = NSScreen.main else { return }
        let preferredWidth = shelfReminderClipID == nil ? Theme.shelfWidth : Theme.shelfReminderWidth
        let width = min(preferredWidth, screen.frame.width - 40)
        let height: CGFloat
        if shelfReminderClipID != nil {
            height = Theme.shelfReminderHeight
        } else {
            height = shelfInspectorClipID == nil ? Theme.shelfHeight : Theme.shelfExpandedHeight
        }
        panel.setContentSize(NSSize(width: width, height: height))
        panel.setFrameOrigin(NSPoint(
            x: screen.frame.midX - width / 2,
            y: screen.frame.maxY - height
        ))
    }

    private func resizeShelf(expanded: Bool) {
        resizeShelf(
            width: Theme.shelfWidth,
            height: expanded ? Theme.shelfExpandedHeight : Theme.shelfHeight
        )
    }

    private func resizeShelf(width preferredWidth: CGFloat, height: CGFloat) {
        guard let panel = shelfPanel, panel.isVisible,
              let screen = NSScreen.screens.first(where: { $0.frame.intersects(panel.frame) }) ?? NSScreen.main
        else { return }

        let width = min(preferredWidth, screen.frame.width - 40)
        let frame = NSRect(
            x: screen.frame.midX - width / 2,
            y: screen.frame.maxY - height,
            width: width,
            height: height
        )
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.28
            context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            panel.animator().setFrame(frame, display: true)
        }
    }

    // MARK: - First-run guide

    /// On first launch, once the menu bar item has had time to appear: a window
    /// opening over a bare desktop, with nothing behind it, reads as a bug.
    private func showOnboardingIfNeeded() {
        guard !preferences.hasCompletedOnboarding else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { [weak self] in
            self?.showOnboarding()
        }
    }

    func showOnboarding() {
        let window = onboardingWindow ?? makeOnboardingWindow()
        onboardingWindow = window
        window.showCentered()
    }

    /// Closes the guide and marks it seen — whether it was finished or skipped.
    func finishOnboarding() {
        preferences.hasCompletedOnboarding = true
        onboardingWindow?.orderOut(nil)
        // The window isn't kept around: reopening from the menu builds a fresh
        // one, starting again from the first step.
        onboardingWindow = nil
    }

    private func makeOnboardingWindow() -> OnboardingWindow {
        OnboardingWindow {
            OnboardingView()
                .environmentObject(self)
                .environmentObject(self.store)
                .environmentObject(self.preferences)
        }
    }

    /// Asks for Accessibility permission and opens the pane where it's granted.
    /// The system prompt alone leads to the same place, but one extra click later.
    func requestAccessibilityPermission() {
        paster.hasAccessibilityPermission(prompt: true)
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }

    private func makeShelfPanel() -> FloatingPanel {
        let panel = FloatingPanel(
            contentRect: NSRect(x: 0, y: 0, width: Theme.shelfWidth, height: Theme.shelfHeight)
        ) {
            NotchShelfView()
                .environmentObject(self)
                .environmentObject(self.store)
                .environmentObject(self.preferences)
        }
        // Above the menu bar: the shelf grows out of the screen edge, not from under it.
        panel.level = NSWindow.Level(rawValue: NSWindow.Level.statusBar.rawValue + 1)
        panel.hasShadow = false
        return panel
    }
}

/// Measurements around the notch on recent MacBook displays.
enum NotchMetrics {
    static func hasNotch(_ screen: NSScreen) -> Bool {
        screen.safeAreaInsets.top > 0
    }

    /// The notch's width, derived from the auxiliary areas either side of it.
    static func notchWidth(for screen: NSScreen) -> CGFloat {
        guard hasNotch(screen) else { return 0 }
        let left = screen.auxiliaryTopLeftArea?.width ?? 0
        let right = screen.auxiliaryTopRightArea?.width ?? 0
        guard left > 0, right > 0 else { return 0 }
        return max(0, screen.frame.width - left - right)
    }

    /// How far to drop the shelf to clear the menu bar, or the notch.
    static func topOffset(for screen: NSScreen) -> CGFloat {
        hasNotch(screen) ? screen.safeAreaInsets.top : screen.frame.height - screen.visibleFrame.maxY
    }
}
