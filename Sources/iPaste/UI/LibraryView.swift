import AppKit
import SwiftUI

/// What the grid is showing.
enum LibraryFilter: Hashable {
    case all
    case pinned
    case category(String)
    case kind(ClipKind)
}

/// The full window: a sidebar of collections and kinds, a grid of clips, and a
/// detail pane for whichever one is selected.
struct LibraryView: View {
    @EnvironmentObject private var app: AppState
    @EnvironmentObject private var store: ClipStore
    @EnvironmentObject private var preferences: Preferences

    @State private var filter: LibraryFilter = .all
    @State private var query = ""
    @State private var selectedID: UUID?
    @State private var newCollection: String?
    @FocusState private var newCollectionFocused: Bool

    private var visibleClips: [Clip] {
        let base: [Clip]
        switch filter {
        case .all:
            base = store.clips(matching: query)
        case .pinned:
            base = store.clips(matching: query).filter(\.pinned)
        case .category(let name):
            base = store.clips(matching: query, category: name)
        case .kind(let kind):
            base = store.clips(matching: query, kind: kind)
        }
        return base
    }

    private var selectedClip: Clip? {
        guard let selectedID else { return nil }
        return store.clips.first { $0.id == selectedID }
    }

    var body: some View {
        NavigationSplitView {
            sidebar
                .navigationSplitViewColumnWidth(min: 190, ideal: 210, max: 260)
        } content: {
            grid
                .navigationSplitViewColumnWidth(min: 380, ideal: 620)
        } detail: {
            inspector
                .navigationSplitViewColumnWidth(min: 260, ideal: 300, max: 380)
        }
        .frame(minWidth: 980, minHeight: 620)
        .background(Color(nsColor: .windowBackgroundColor))
    }

    // MARK: - Sidebar

    private var sidebar: some View {
        List(selection: Binding(get: { filter }, set: { filter = $0 ?? .all })) {
            Section("Library") {
                row(.all, "All", "tray.full", store.clips.count)
                row(.pinned, "Pinned", "pin", store.clips.count { $0.pinned })
            }

            Section("Collections") {
                ForEach(store.categories, id: \.self) { category in
                    row(.category(category), category, "folder", store.count(inCategory: category))
                        .contextMenu {
                            Button("Delete collection", role: .destructive) {
                                if filter == .category(category) { filter = .all }
                                store.removeCategory(category)
                            }
                        }
                }
                if let draft = newCollection {
                    TextField("Collection name", text: Binding(
                        get: { draft }, set: { newCollection = $0 }
                    ))
                    .focused($newCollectionFocused)
                    .onSubmit {
                        if store.addCategory(draft) { filter = .category(draft) }
                        newCollection = nil
                    }
                    .onExitCommand { newCollection = nil }
                } else {
                    Button {
                        newCollection = ""
                        newCollectionFocused = true
                    } label: {
                        Label("New collection", systemImage: "plus")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }

            Section("Kinds") {
                ForEach(ClipKind.allCases, id: \.self) { kind in
                    let count = store.clips.count { $0.kind == kind }
                    if count > 0 {
                        row(.kind(kind), kind.label, kind.symbol, count)
                    }
                }
            }
        }
        .listStyle(.sidebar)
    }

    private func row(_ value: LibraryFilter, _ title: String, _ symbol: String, _ count: Int) -> some View {
        HStack {
            Label(title, systemImage: symbol)
            Spacer()
            Text("\(count)")
                .font(.system(size: 11))
                .foregroundStyle(.tertiary)
        }
        .tag(value)
    }

    // MARK: - Grid

    private var grid: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
                TextField("Search the library…", text: $query)
                    .textFieldStyle(.plain)
                Spacer()
                Text("\(visibleClips.count)")
                    .font(.system(size: 11))
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 14)
            .frame(height: 40)

            Divider()

            filterTabs

            Divider()

            if visibleClips.isEmpty {
                emptyState
            } else {
                ScrollView {
                    LazyVGrid(
                        columns: [GridItem(.adaptive(minimum: 170, maximum: 240), spacing: 12)],
                        spacing: 12
                    ) {
                        ForEach(visibleClips) { clip in
                            LibraryCard(clip: clip, isSelected: clip.id == selectedID)
                                .onTapGesture { selectedID = clip.id }
                                .simultaneousGesture(TapGesture(count: 2).onEnded {
                                    app.activate(clip)
                                })
                                .contextMenu { cardMenu(for: clip) }
                        }
                    }
                    .padding(14)
                }
            }
        }
    }

    /// A compact visual timeline of the library's main destinations. The
    /// sidebar remains useful for the full taxonomy, while these pills keep
    /// the common History / collection flow close to the clip grid.
    private var filterTabs: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 7) {
                filterTab(.all, title: "History", count: store.clips.count)
                filterTab(.pinned, title: "Pinned", count: store.clips.count { $0.pinned })

                ForEach(store.categories, id: \.self) { category in
                    filterTab(
                        .category(category),
                        title: category,
                        count: store.count(inCategory: category)
                    )
                }

                ForEach(ClipKind.allCases, id: \.self) { kind in
                    let count = store.clips.count { $0.kind == kind }
                    if count > 0 {
                        filterTab(.kind(kind), title: kind.label, count: count)
                    }
                }

                Button {
                    newCollection = ""
                    newCollectionFocused = true
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 11, weight: .semibold))
                        .frame(width: 27, height: 27)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
                .background(Color.primary.opacity(0.06), in: Capsule())
                .help("New collection")
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
        }
    }

    private func filterTab(_ value: LibraryFilter, title: String, count: Int) -> some View {
        Button {
            filter = value
        } label: {
            HStack(spacing: 5) {
                Text(title)
                Text("\(count)")
                    .foregroundStyle(filter == value ? .secondary : .tertiary)
            }
            .font(.system(size: 11, weight: filter == value ? .semibold : .regular))
            .padding(.horizontal, 11)
            .frame(height: 27)
            .background(
                Capsule().fill(filter == value ? Color.primary.opacity(0.12) : Color.clear)
            )
        }
        .buttonStyle(.plain)
        .foregroundStyle(filter == value ? .primary : .secondary)
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "tray")
                .font(.system(size: 30))
                .foregroundStyle(.tertiary)
            Text(query.isEmpty ? "Nothing here yet." : "No results for \"\(query)\"")
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    @ViewBuilder
    private func cardMenu(for clip: Clip) -> some View {
        Button("Paste") { app.paste(clip) }
        Button("Copy") { app.copy(clip) }
        Divider()
        Button(clip.pinned ? "Unpin" : "Pin") { store.togglePin(clip) }
        ClipReminderMenu(clip: clip)
        if !store.categories.isEmpty {
            Menu("Move to collection") {
                Button("No collection") { store.setCategory(nil, for: clip) }
                Divider()
                ForEach(store.categories, id: \.self) { category in
                    Button(clip.category == category ? "✓ \(category)" : category) {
                        store.setCategory(category, for: clip)
                    }
                }
            }
        }
        Divider()
        if let bundleID = clip.sourceBundleID, let appName = clip.sourceAppName {
            Button("Ignore future clips from \(appName)") {
                preferences.ignoreApplication(bundleID: bundleID, name: appName)
            }
        }
        Button("Delete", role: .destructive) { store.delete(clip) }
    }

    // MARK: - Details

    @ViewBuilder
    private var inspector: some View {
        if let clip = selectedClip {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        Label("History", systemImage: "arrow.up.right")
                            .font(.system(size: 13, weight: .medium))
                        Spacer()
                        Button {
                            store.togglePin(clip)
                        } label: {
                            Image(systemName: clip.pinned ? "star.fill" : "star")
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(clip.pinned ? .yellow : .secondary)
                        .help(clip.pinned ? "Unpin" : "Pin")
                    }

                    ClipPreview(clip: clip)
                        .frame(maxWidth: .infinity)

                    VStack(alignment: .leading, spacing: 6) {
                        detailRow("Kind", clip.kind.label)
                        if let appName = clip.sourceAppName { detailRow("App", appName) }
                        detailRow("Copied", clip.createdAt.formatted(date: .abbreviated, time: .shortened))
                        if let reminder = clip.reminder { detailRow("Reminder", reminder.label) }
                        if clip.byteSize > 0 { detailRow("Size", clip.byteSize.formattedByteSize) }
                        detailRow("Collection", clip.category ?? "—")
                        if let ocr = clip.ocrText, !ocr.isEmpty {
                            detailRow("Text in image", ocr.truncated(to: 60))
                        }
                    }

                    HStack(spacing: 8) {
                        Button("Paste") { app.paste(clip) }
                            .primaryActionStyle()
                        Button("Copy") { app.copy(clip) }
                        Spacer()
                        Button {
                            store.togglePin(clip)
                        } label: {
                            Image(systemName: clip.pinned ? "pin.fill" : "pin")
                        }
                        .help(clip.pinned ? "Unpin" : "Pin")
                    }
                }
                .padding(16)
            }
        } else {
            Text("Select a clip")
                .foregroundStyle(.tertiary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private func detailRow(_ label: String, _ value: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text(label)
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
                .frame(width: 96, alignment: .leading)
            Text(value)
                .font(.system(size: 11))
                .textSelection(.enabled)
            Spacer(minLength: 0)
        }
    }
}

/// A clip's full content, as shown in the detail pane.
private struct ClipPreview: View {
    let clip: Clip
    @EnvironmentObject private var store: ClipStore

    var body: some View {
        switch clip.kind {
        case .image:
            if let image = store.image(for: clip) {
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxHeight: 220)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
        case .color:
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color(nsColor: clip.color ?? .gray))
                .frame(height: 90)
                .overlay(
                    Text(clip.text.uppercased())
                        .font(.system(size: 13, weight: .semibold, design: .monospaced))
                        .foregroundStyle(.white)
                        .shadow(radius: 2)
                )
        default:
            Text(clip.text)
                .font(.system(size: 12, design: clip.kind == .code ? .monospaced : .default))
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(10)
                .background(Color.primary.opacity(0.05), in: RoundedRectangle(cornerRadius: 8))
        }
    }
}

/// One card in the grid.
private struct LibraryCard: View {
    let clip: Clip
    let isSelected: Bool

    @EnvironmentObject private var store: ClipStore

    var body: some View {
        VStack(spacing: 0) {
            preview
                .frame(height: 104)
                .frame(maxWidth: .infinity)
                .clipped()

            HStack(spacing: 5) {
                if let icon = AppIconProvider.icon(forBundleID: clip.sourceBundleID) {
                    Image(nsImage: icon).resizable().frame(width: 12, height: 12)
                }
                Text(clip.createdAt.relativeShort)
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
                Spacer(minLength: 0)
                if clip.reminder != nil {
                    Image(systemName: "bell.fill")
                        .font(.system(size: 9))
                        .foregroundStyle(Color.accentColor)
                }
                if clip.pinned {
                    Image(systemName: "pin.fill")
                        .font(.system(size: 9))
                        .foregroundStyle(.orange)
                }
            }
            .padding(.horizontal, 8)
            .frame(height: 26)
        }
        .background(Color.primary.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(
                    isSelected ? Color.accentColor : Color.primary.opacity(0.08),
                    lineWidth: isSelected ? 2 : 1
                )
        }
        .help(clip.title)
    }

    @ViewBuilder
    private var preview: some View {
        switch clip.kind {
        case .image:
            if let image = store.image(for: clip) {
                Image(nsImage: image).resizable().aspectRatio(contentMode: .fill)
            } else {
                symbolTile
            }
        case .color:
            Color(nsColor: clip.color ?? .gray)
                .overlay(alignment: .bottomLeading) {
                    Text(clip.text.uppercased())
                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                        .foregroundStyle(.white)
                        .shadow(radius: 2)
                        .padding(8)
                }
        case .file:
            VStack(spacing: 4) {
                Image(nsImage: NSWorkspace.shared.icon(forFile: clip.text.components(separatedBy: "\n")[0]))
                    .resizable().frame(width: 34, height: 34)
                Text(clip.title).font(.system(size: 10)).lineLimit(1).padding(.horizontal, 6)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        default:
            Text(clip.text)
                .font(.system(size: 11, design: clip.kind == .code ? .monospaced : .default))
                .lineLimit(5)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .padding(8)
        }
    }

    private var symbolTile: some View {
        Image(systemName: clip.kind.symbol)
            .font(.system(size: 20))
            .foregroundStyle(.tertiary)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
