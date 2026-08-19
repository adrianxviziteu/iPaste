import AppKit
import SwiftUI

/// The menu bar menu: the latest clips plus the main commands.
struct MenuBarContentView: View {
    @EnvironmentObject private var app: AppState
    /// Observed directly: a change in the history must redraw this at once.
    @EnvironmentObject private var store: ClipStore

    private var recent: [Clip] {
        Array(store.orderedClips.prefix(8))
    }

    var body: some View {
        Group {
            Button("Quick Search…") { app.showQuickSearch() }
                .keyboardShortcut("v", modifiers: [.control, .command])

            Button("Quick Note…") { app.showQuickNotes() }
                .keyboardShortcut("n", modifiers: [.control, .command])

            Button("Clipboard Library…") { app.showLibrary() }
                .keyboardShortcut("l", modifiers: [.control, .command])

            Button("Capture Selected Text") { app.captureSelectedText() }
            Button("Color Picker…") { app.pickColor() }

            Button(app.isShelfVisible ? "Hide Shelf" : "Show Shelf") { app.toggleShelf() }
                .keyboardShortcut("s", modifiers: [.control, .command])

            Divider()

            Button("Settings…") { app.showSettings() }
                .keyboardShortcut(",", modifiers: [.command])

            if recent.isEmpty {
                Text("No clips yet")
            } else {
                ForEach(Array(recent.enumerated()), id: \.element.id) { index, clip in
                    Button("\(index)  \(clip.title.truncated(to: 44))") {
                        app.activate(clip)
                    }
                }
            }

            Divider()

            Button("Show Guide…") { app.showOnboarding() }

            Divider()

            Button("Clear History") { store.clearHistory() }
            Button("Quit iPaste") { NSApp.terminate(nil) }
                .keyboardShortcut("q")
        }
    }
}

extension String {
    func truncated(to limit: Int) -> String {
        count <= limit ? self : String(prefix(limit - 1)) + "…"
    }
}
