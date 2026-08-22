import AppKit

/// Watches ordinary typing outside iPaste and expands an exact `;shortcut`.
/// It deliberately keeps no keystrokes and only acts after a stored shortcut
/// has matched, so snippets remain local and predictable.
@MainActor
final class SnippetExpansionMonitor {
    private let store: ClipStore
    private let paster: Paster
    private var monitor: Any?
    private var typed = ""

    init(store: ClipStore, paster: Paster) {
        self.store = store
        self.paster = paster
    }

    func start() {
        guard monitor == nil else { return }
        monitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            Task { @MainActor in self?.handle(event) }
        }
    }

    func stop() {
        if let monitor { NSEvent.removeMonitor(monitor) }
        monitor = nil
        typed = ""
    }

    private func handle(_ event: NSEvent) {
        guard event.modifierFlags.intersection([.command, .control, .option]).isEmpty else {
            typed = ""
            return
        }
        if event.keyCode == 51 { // delete
            typed = String(typed.dropLast())
            return
        }
        guard let characters = event.characters, characters.count == 1,
              let character = characters.first, !character.isWhitespace
        else {
            typed = ""
            return
        }
        typed.append(character)
        typed = String(typed.suffix(64))
        guard typed.hasPrefix(";"), let clip = store.clip(withShortcut: typed) else { return }
        paster.expandSnippet(clip.text, replacingLastTypedCharacters: typed.count)
        store.markUsed(clip)
        typed = ""
    }
}
