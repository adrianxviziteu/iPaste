import SwiftUI

/// A small focused editor for saving an idea without first putting it on the
/// system clipboard. Each saved note becomes a normal searchable text clip.
struct QuickNotesView: View {
    @EnvironmentObject private var app: AppState
    @State private var note = ""
    @FocusState private var editorFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Write something worth keeping")
                .font(.headline)

            TextEditor(text: $note)
                .font(.system(size: 14))
                .focused($editorFocused)
                .scrollContentBackground(.hidden)
                .padding(8)
                .background(Color.primary.opacity(0.06), in: RoundedRectangle(cornerRadius: 8))

            HStack {
                Text("\(note.trimmingCharacters(in: .whitespacesAndNewlines).count) characters")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Button("Save Note") { save(copy: false) }
                    .keyboardShortcut(.return, modifiers: [.command])
                    .disabled(note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                Button("Save & Copy") { save(copy: true) }
                    .primaryActionStyle()
                    .disabled(note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding(18)
        .frame(minWidth: 460, minHeight: 300)
        .onAppear { editorFocused = true }
    }

    private func save(copy: Bool) {
        guard app.saveQuickNote(note, copyToClipboard: copy) else { return }
        note = ""
        editorFocused = true
    }
}
