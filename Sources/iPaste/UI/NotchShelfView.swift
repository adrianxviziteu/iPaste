import AppKit
import SwiftUI
import UniformTypeIdentifiers

private struct SourceAppFilter: Identifiable {
    let id: String
    let name: String
    let bundleID: String?
}

private struct IndexedShelfClip: Identifiable {
    let index: Int
    let clip: Clip
    var id: UUID { clip.id }
}

private struct ShelfDayGroup: Identifiable {
    let day: Date
    let title: String
    let clips: [IndexedShelfClip]
    var id: Date { day }
}

/// The shelf hanging from the top edge of the screen, merged into the notch.
///
/// Three bands: search, collections, cards. The cards are dominated by their
/// preview — a shelf is reached for by eye rather than read, so the picture
/// matters more than the text.
struct NotchShelfView: View {
    @EnvironmentObject private var app: AppState
    @EnvironmentObject private var store: ClipStore
    @EnvironmentObject private var preferences: Preferences

    @State private var query = ""
    /// nil means the "History" collection — everything that was copied.
    @State private var activeCategory: String?
    /// The name being typed; nil when nothing is being edited.
    @State private var draftName: String?
    /// The collection being renamed; nil when creating a new one.
    @State private var renamingCategory: String?
    /// A second, independent dimension of the shelf filter.
    @State private var activeKind: ClipKind?
    @State private var activeSourceID: String?
    @State private var activeSmartFilter: SmartFilter?
    @FocusState private var draftFocused: Bool
    @State private var showsPinnedOnly = false
    @AppStorage("shelfShowsList") private var showsList = false
    @State private var showsClearHistoryConfirmation = false
    /// Lets the active pill's background slide from one pill to the next
    /// instead of blinking out here and in again over there.
    @Namespace private var pillNamespace

    private var filteredClips: [Clip] {
        var result = store.clips(matching: query, kind: activeKind, category: activeCategory)
        if showsPinnedOnly { result = result.filter(\.pinned) }
        if let activeSourceID {
            result = result.filter { sourceID(for: $0) == activeSourceID }
        }
        if preferences.smartFiltersEnabled, let activeSmartFilter {
            result = result.filter { SmartClipClassifier.matches(activeSmartFilter, clip: $0) }
        }
        return result
    }

    private var clips: [Clip] {
        Array(filteredClips.prefix(24))
    }

    private var sourceApps: [SourceAppFilter] {
        var seen = Set<String>()
        return store.orderedClips.compactMap { clip in
            guard let name = clip.sourceAppName, !name.isEmpty else { return nil }
            let id = sourceID(for: clip)
            guard seen.insert(id).inserted else { return nil }
            return SourceAppFilter(id: id, name: name, bundleID: clip.sourceBundleID)
        }
    }

    /// List mode is a recency view: pinned clips do not displace newer copies.
    private var listClips: [Clip] {
        Array(filteredClips.sorted { $0.createdAt > $1.createdAt }.prefix(5))
    }

    private var selectedClip: Clip? {
        guard let id = app.shelfInspectorClipID else { return nil }
        return store.clips.first { $0.id == id }
    }

    private var reminderClip: Clip? {
        guard let id = app.shelfReminderClipID else { return nil }
        return store.clips.first { $0.id == id }
    }

    private var shelfHeight: CGFloat {
        if reminderClip != nil { return Theme.shelfReminderHeight }
        let baseHeight = showsList ? listShelfHeight : Theme.shelfHeight
        let inspectorHeight = Theme.shelfExpandedHeight - Theme.shelfHeight
        return selectedClip == nil ? baseHeight : baseHeight + inspectorHeight
    }

    private var listShelfHeight: CGFloat {
        let rowCount = min(listClips.count, 5)
        guard rowCount > 0 else { return Theme.shelfHeight }

        let rows = CGFloat(rowCount) * Theme.shelfListRowHeight
        let gaps = CGFloat(max(rowCount - 1, 0)) * Theme.shelfListRowSpacing
        let listContentHeight = rows + gaps + Theme.shelfListVerticalPadding
        let shelfChromeHeight = Theme.shelfHeight - Theme.shelfCardsRowHeight
        return max(Theme.shelfHeight, shelfChromeHeight + listContentHeight)
    }

    private var shelfWidth: CGFloat {
        reminderClip == nil ? Theme.shelfWidth : Theme.shelfReminderWidth
    }

    private var dayGroups: [ShelfDayGroup] {
        let calendar = Calendar.current
        let indexed = clips.enumerated().map { IndexedShelfClip(index: $0.offset, clip: $0.element) }
        let grouped = Dictionary(grouping: indexed) { calendar.startOfDay(for: $0.clip.createdAt) }
        return grouped.keys.sorted(by: >).map { day in
            ShelfDayGroup(
                day: day,
                title: dayTitle(day),
                clips: (grouped[day] ?? []).sorted { $0.clip.createdAt > $1.clip.createdAt }
            )
        }
    }

    var body: some View {
        Group {
            if let reminderClip {
                ShelfReminderPicker(
                    clip: reminderClip,
                    onCancel: { app.closeShelfReminderPicker() },
                    onSave: { date in
                        app.setReminder(.at(date), for: reminderClip)
                        app.closeShelfReminderPicker()
                    }
                )
                .padding(12)
                .transition(.opacity.combined(with: .scale(scale: 0.97, anchor: .top)))
            } else {
                VStack(alignment: .leading, spacing: 12) {
                    if showsClearHistoryConfirmation {
                        clearHistoryRow
                            .transition(.move(edge: .top).combined(with: .opacity))
                    } else {
                        searchRow
                            .transition(.move(edge: .top).combined(with: .opacity))
                    }
                    collectionsRow
                        .opacity(showsClearHistoryConfirmation ? 0.42 : 1)
                        .allowsHitTesting(!showsClearHistoryConfirmation)
                    cardsRow
                        .opacity(showsClearHistoryConfirmation ? 0.42 : 1)
                        .allowsHitTesting(!showsClearHistoryConfirmation)
                    if let selectedClip {
                        ShelfInspectorView(clip: selectedClip)
                            .id(selectedClip.id)
                            .transition(.move(edge: .top).combined(with: .opacity))
                    }
                }
                .padding(.top, 10)
                .padding(.bottom, 16)
                .transition(.opacity)
            }
        }
        .frame(width: shelfWidth, height: shelfHeight, alignment: .top)
        .background(Color.black)
        .clipShape(BottomRoundedRectangle(radius: Theme.shelfCornerRadius))
        .overlay { dropOverlay }
        .environment(\.colorScheme, .dark)
        // The window stays put and only the content moves, so the animation is
        // composited on the GPU instead of stuttering the way resizing a window did.
        .offset(y: app.isShelfVisible ? 0 : -shelfHeight)
        .opacity(app.isShelfVisible ? 1 : 0)
        .animation(
            app.isShelfVisible
                ? .spring(response: 0.42, dampingFraction: 0.80)
                : .spring(response: 0.30, dampingFraction: 1.0),
            value: app.isShelfVisible
        )
        .animation(.spring(response: 0.3, dampingFraction: 0.84), value: showsClearHistoryConfirmation)
        .animation(.spring(response: 0.34, dampingFraction: 0.84), value: app.shelfInspectorClipID)
        .animation(.spring(response: 0.34, dampingFraction: 0.84), value: app.shelfReminderClipID)
        .onDrop(of: [
            UTType.fileURL.identifier,
            UTType.image.identifier,
            UTType.text.identifier,
            UTType.url.identifier
        ], isTargeted: $app.isDropTargeted) { providers in
            app.isDropTargeted = false
            return app.captureDroppedProviders(providers)
        }
    }

    @ViewBuilder
    private var dropOverlay: some View {
        if app.isDropTargeted {
            ZStack {
                Color.black.opacity(0.94)

                VStack(spacing: 7) {
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.12))
                            .frame(width: 44, height: 44)
                        Image(systemName: "arrow.down.to.line")
                            .font(.system(size: 19, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                    .overlay {
                        Circle()
                            .stroke(Color.white.opacity(0.28), lineWidth: 1)
                    }
                    Text("Drop to save")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.white.opacity(0.88))
                }
                .transition(.scale(scale: 0.82).combined(with: .opacity))
            }
            .clipShape(BottomRoundedRectangle(radius: Theme.shelfCornerRadius))
            .overlay {
                BottomRoundedRectangle(radius: Theme.shelfCornerRadius)
                    .stroke(Color.white.opacity(0.42), lineWidth: 1.5)
                    .shadow(color: .white.opacity(0.18), radius: 12)
            }
            .allowsHitTesting(false)
            .animation(.spring(response: 0.28, dampingFraction: 0.72), value: app.isDropTargeted)
        }
    }

    private var clearHistoryRow: some View {
        HStack(spacing: 10) {
            Image(systemName: "trash")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.red.opacity(0.88))
                .frame(width: 28, height: 28)
                .background(Color.red.opacity(0.12), in: Circle())

            Text("Clear history?")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.white)

            Text("Pinned clips stay.")
                .font(.system(size: 10))
                .foregroundStyle(.white.opacity(0.4))

            Spacer(minLength: 8)

            Button("Cancel") {
                showsClearHistoryConfirmation = false
            }
            .buttonStyle(InlineConfirmationButtonStyle(prominent: false))

            Button("Clear") {
                store.clearHistory()
                showsClearHistoryConfirmation = false
            }
            .buttonStyle(InlineConfirmationButtonStyle(prominent: true, destructive: true))
        }
        .padding(.horizontal, 18)
        .frame(height: 32)
    }

    // MARK: - Search

    private var searchRow: some View {
        HStack(spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 13))
                    .foregroundStyle(.white.opacity(0.45))
                TextField("Search…", text: $query)
                    .textFieldStyle(.plain)
                    .font(.system(size: 13))
                    .foregroundStyle(.white)
            }

            Spacer(minLength: 8)

            circleButton(showsPinnedOnly ? "star.fill" : "star",
                         active: showsPinnedOnly,
                         help: "Pinned clips only") { showsPinnedOnly.toggle() }
            circleButton(showsList ? "square.grid.2x2" : "list.bullet",
                         active: showsList,
                         help: showsList ? "Card view" : "List view") {
                withAnimation(.spring(response: 0.32, dampingFraction: 0.8)) {
                    showsList.toggle()
                }
            }
            circleButton("trash", tint: .closeRed, help: "Clear history") {
                showsClearHistoryConfirmation = true
            }
            circleButton("xmark", tint: .closeRed, help: "Close shelf") { app.hideShelf() }
        }
        .padding(.horizontal, 18)
    }

    private func circleButton(
        _ symbol: String,
        active: Bool = false,
        tint: Color? = nil,
        help: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(active ? .black : (tint ?? .white.opacity(0.75)))
                .frame(width: 32, height: 32)
                .background(
                    active ? Color.white
                           : (tint?.opacity(0.16) ?? Color.white.opacity(0.09)),
                    in: Circle()
                )
        }
        .buttonStyle(.plain)
        .help(help)
    }

    // MARK: - Collections

    private var collectionsRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                pill(title: "History", count: store.clips.count, category: nil)

                ForEach(store.categories, id: \.self) { category in
                    if renamingCategory == category {
                        nameField(placeholder: category)
                    } else {
                        pill(
                            title: category,
                            count: store.count(inCategory: category),
                            category: category
                        )
                        .contextMenu {
                            Button("Rename") { startRenaming(category) }
                            Button("Delete collection", role: .destructive) {
                                if activeCategory == category { activeCategory = nil }
                                store.removeCategory(category)
                            }
                        }
                    }
                }

                if renamingCategory == nil, draftName != nil {
                    nameField(placeholder: "Collection name")
                } else {
                    addButton
                }

                Divider()
                    .frame(height: 18)
                    .padding(.horizontal, 3)

                sourceFilterMenu
                if preferences.smartFiltersEnabled {
                    smartFilterMenu
                }

                Divider()
                    .frame(height: 18)
                    .padding(.horizontal, 3)

                kindPill(title: "All types", kind: nil)
                ForEach(ClipKind.allCases, id: \.self) { kind in
                    kindPill(
                        title: kind.label,
                        kind: kind,
                        count: store.clips(matching: "", kind: kind, category: activeCategory).count
                    )
                }
            }
            .padding(.horizontal, 18)
        }
        .frame(height: 30)
        .animation(.spring(response: 0.32, dampingFraction: 0.78), value: activeCategory)
        .animation(.spring(response: 0.32, dampingFraction: 0.78), value: activeKind)
        .animation(.spring(response: 0.32, dampingFraction: 0.78), value: activeSourceID)
        .animation(.spring(response: 0.32, dampingFraction: 0.78), value: activeSmartFilter)
    }

    private var sourceFilterMenu: some View {
        Menu {
            Button("All applications") { activeSourceID = nil }
            if !sourceApps.isEmpty { Divider() }
            ForEach(sourceApps) { source in
                Button {
                    activeSourceID = source.id
                } label: {
                    Text(activeSourceID == source.id ? "✓ \(source.name)" : source.name)
                }
            }
        } label: {
            HStack(spacing: 6) {
                if let selected = sourceApps.first(where: { $0.id == activeSourceID }),
                   let icon = AppIconProvider.icon(forBundleID: selected.bundleID) {
                    Image(nsImage: icon).resizable().frame(width: 13, height: 13)
                } else {
                    Image(systemName: "app.dashed")
                        .font(.system(size: 10, weight: .medium))
                }
                Text(sourceApps.first(where: { $0.id == activeSourceID })?.name ?? "All apps")
                    .font(.system(size: 11, weight: .medium))
                    .lineLimit(1)
                Image(systemName: "chevron.down")
                    .font(.system(size: 7, weight: .bold))
                    .opacity(0.45)
            }
            .foregroundStyle(activeSourceID == nil ? .white.opacity(0.8) : .black)
            .padding(.horizontal, 10)
            .frame(height: 30)
            .background(activeSourceID == nil ? Color.white.opacity(0.08) : Color.white, in: Capsule())
        }
        .menuStyle(.borderlessButton)
        .fixedSize()
        .help("Filter by source application")
    }

    private var smartFilterMenu: some View {
        Menu {
            Button("All smart filters") { activeSmartFilter = nil }
            Divider()
            ForEach(SmartFilter.allCases) { filter in
                Button {
                    activeSmartFilter = filter
                } label: {
                    Label(activeSmartFilter == filter ? "✓ \(filter.label)" : filter.label,
                          systemImage: filter.symbol)
                }
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: activeSmartFilter?.symbol ?? "sparkles")
                    .font(.system(size: 10, weight: .medium))
                Text(activeSmartFilter?.label ?? "Smart")
                    .font(.system(size: 11, weight: .medium))
                Image(systemName: "chevron.down")
                    .font(.system(size: 7, weight: .bold))
                    .opacity(0.45)
            }
            .foregroundStyle(activeSmartFilter == nil ? .white.opacity(0.8) : .black)
            .padding(.horizontal, 10)
            .frame(height: 30)
            .background(activeSmartFilter == nil ? Color.white.opacity(0.08) : Color.white, in: Capsule())
        }
        .menuStyle(.borderlessButton)
        .fixedSize()
        .help("Smart Auto-Filter")
    }

    private func sourceID(for clip: Clip) -> String {
        clip.sourceBundleID ?? "name:\(clip.sourceAppName ?? "Unknown")"
    }

    private var addButton: some View {
        Button {
            renamingCategory = nil
            draftName = ""
            draftFocused = true
        } label: {
            Image(systemName: "plus")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.white.opacity(0.7))
                .frame(width: 30, height: 30)
                .background(Color.white.opacity(0.08), in: Circle())
        }
        .buttonStyle(.plain)
        .help("New collection")
    }

    /// The field appears in place, in the row of pills — not in a separate window.
    private func nameField(placeholder: String) -> some View {
        TextField(placeholder, text: Binding(
            get: { draftName ?? "" },
            set: { draftName = $0 }
        ))
        .textFieldStyle(.plain)
        .font(.system(size: 12, weight: .medium))
        .foregroundStyle(.white)
        .focused($draftFocused)
        .frame(width: 130)
        .padding(.horizontal, 12)
        .frame(height: 30)
        .background(Color.white.opacity(0.14), in: Capsule())
        .overlay(Capsule().strokeBorder(Color.white.opacity(0.25), lineWidth: 1))
        .onSubmit { commitDraft() }
        .onExitCommand { cancelDraft() }
        .onAppear { draftFocused = true }
    }

    private func startRenaming(_ category: String) {
        renamingCategory = category
        draftName = category
        draftFocused = true
    }

    private func commitDraft() {
        defer { cancelDraft() }
        guard let name = draftName?.trimmingCharacters(in: .whitespacesAndNewlines),
              !name.isEmpty else { return }

        if let old = renamingCategory {
            if store.renameCategory(old, to: name), activeCategory == old {
                activeCategory = name
            }
        } else if store.addCategory(name) {
            activeCategory = name
        }
    }

    private func cancelDraft() {
        draftName = nil
        renamingCategory = nil
        draftFocused = false
    }

    private func pill(title: String, count: Int, category: String?) -> some View {
        let isActive = activeCategory == category
        return Button {
            activeCategory = category
        } label: {
            HStack(spacing: 6) {
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(isActive ? .black : .white.opacity(0.8))
                Text("\(count)")
                    .font(.system(size: 12))
                    .foregroundStyle(isActive ? .black.opacity(0.45) : .white.opacity(0.35))
            }
            .padding(.horizontal, 12)
            .frame(height: 30)
            .background {
                if isActive {
                    Capsule()
                        .fill(Color.white)
                        .matchedGeometryEffect(id: "activeCollection", in: pillNamespace)
                } else {
                    Capsule().fill(Color.white.opacity(0.08))
                }
            }
        }
        .buttonStyle(.plain)
    }

    private func kindPill(title: String, kind: ClipKind?, count: Int? = nil) -> some View {
        let isActive = activeKind == kind
        return Button {
            activeKind = kind
        } label: {
            HStack(spacing: 5) {
                if let kind {
                    Image(systemName: kind.symbol)
                        .font(.system(size: 10, weight: .medium))
                }
                Text(title)
                    .font(.system(size: 11, weight: .medium))
                if let count {
                    Text("\(count)")
                        .font(.system(size: 11))
                        .foregroundStyle(isActive ? .black.opacity(0.45) : .white.opacity(0.35))
                }
            }
            .foregroundStyle(isActive ? .black : .white.opacity(0.8))
            .padding(.horizontal, 10)
            .frame(height: 30)
            .background(isActive ? Color.white : Color.white.opacity(0.08), in: Capsule())
        }
        .buttonStyle(.plain)
        .help("Show \(title.lowercased()) clips")
    }

    // MARK: - Cards

    @ViewBuilder
    private var cardsRow: some View {
        if clips.isEmpty {
            Text(emptyStateMessage)
                .font(.system(size: 12))
                .foregroundStyle(.white.opacity(0.35))
                .frame(maxWidth: .infinity, alignment: .center)
                .frame(height: Theme.shelfCardsRowHeight)
        } else {
            if showsList {
                ScrollView(.vertical, showsIndicators: false) {
                    LazyVStack(spacing: Theme.shelfListRowSpacing) {
                        ForEach(Array(listClips.enumerated()), id: \.element.id) { index, clip in
                            ShelfListRow(clip: clip, index: index)
                        }
                    }
                    .padding(.horizontal, 18)
                    .padding(.vertical, Theme.shelfListVerticalPadding / 2)
                }
                .frame(height: listShelfHeight - (Theme.shelfHeight - Theme.shelfCardsRowHeight))
                .transition(.opacity.combined(with: .scale(scale: 0.98, anchor: .top)))
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(alignment: .top, spacing: 18) {
                        ForEach(dayGroups) { group in
                            VStack(alignment: .leading, spacing: 5) {
                                Text(group.title)
                                    .font(.system(size: 9, weight: .semibold))
                                    .foregroundStyle(.white.opacity(0.42))
                                    .padding(.leading, 2)
                                HStack(spacing: 10) {
                                    ForEach(group.clips) { item in
                                        ShelfCard(clip: item.clip, index: item.index)
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 18)
                    .padding(.vertical, Theme.shelfCardBreathingRoom)
                }
                .frame(height: Theme.shelfCardsRowHeight)
                .transition(.opacity.combined(with: .scale(scale: 0.98, anchor: .top)))
            }
        }
    }

    private var emptyStateMessage: String {
        if !query.isEmpty { return "No match for \"\(query)\"" }
        if let activeKind { return "No \(activeKind.label.lowercased()) clips yet." }
        if activeCategory != nil { return "This collection is empty." }
        return "Copy something and it shows up here."
    }

    private func dayTitle(_ day: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(day) { return "Today" }
        if calendar.isDateInYesterday(day) { return "Yesterday" }
        return day.formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day())
    }
}

private struct InlineConfirmationButtonStyle: ButtonStyle {
    let prominent: Bool
    var destructive = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 10, weight: .semibold))
            .foregroundStyle(prominent ? (destructive ? .white : .black) : .white.opacity(0.78))
            .padding(.horizontal, 11)
            .frame(height: 29)
            .background(
                prominent
                    ? (destructive ? Color.red.opacity(0.86) : Color.white)
                    : Color.white.opacity(0.09),
                in: Capsule()
            )
            .overlay {
                if !prominent {
                    Capsule().strokeBorder(Color.white.opacity(0.15), lineWidth: 1)
                }
            }
            .opacity(configuration.isPressed ? 0.72 : 1)
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

private struct ShelfInspectorView: View {
    let clip: Clip

    @EnvironmentObject private var app: AppState
    @EnvironmentObject private var store: ClipStore
    @State private var draftText: String
    @State private var isEditing = false

    init(clip: Clip) {
        self.clip = clip
        _draftText = State(initialValue: clip.text)
    }

    var body: some View {
        VStack(spacing: 10) {
            inspectorToolbar
            inspectorContent
        }
        .padding(12)
        .frame(height: 218)
        .background(Color.white.opacity(0.055), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(Color.white.opacity(0.11), lineWidth: 1)
        }
        .padding(.horizontal, 18)
    }

    private var inspectorToolbar: some View {
        HStack(spacing: 7) {
            Label(clip.kind.label, systemImage: clip.kind.symbol)
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(.white.opacity(0.68))
                .padding(.horizontal, 8)
                .frame(height: 24)
                .background(Color.white.opacity(0.08), in: Capsule())

            if let category = clip.category {
                Text(category)
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(.white.opacity(0.58))
                    .padding(.horizontal, 8)
                    .frame(height: 24)
                    .background(Color.white.opacity(0.07), in: Capsule())
            }

            if isTextual {
                metric("\(clip.text.count) characters")
                metric("\(wordCount) words")
            } else if clip.byteSize > 0 {
                metric(clip.byteSize.formattedByteSize)
            }

            Spacer(minLength: 8)

            inspectorButton(
                clip.reminder == nil ? "bell" : "bell.fill",
                help: clip.reminder == nil ? "Set reminder" : "Change reminder"
            ) {
                app.showShelfReminderPicker(for: clip)
            }

            copyMenu

            if isEditable {
                inspectorButton(isEditing ? "checkmark" : "pencil", help: isEditing ? "Save" : "Edit") {
                    if isEditing { store.updateText(draftText, for: clip) }
                    withAnimation(.easeOut(duration: 0.16)) { isEditing.toggle() }
                }
            }

            inspectorButton("xmark", help: "Close inspector") {
                app.closeShelfInspector()
            }
        }
    }

    private func metric(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 8, weight: .medium))
            .foregroundStyle(.white.opacity(0.38))
            .padding(.horizontal, 7)
            .frame(height: 22)
            .background(Color.black.opacity(0.18), in: Capsule())
    }

    private func inspectorButton(_ symbol: String, help: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 9, weight: .semibold))
                .foregroundStyle(.white.opacity(0.72))
                .frame(width: 26, height: 26)
                .background(Color.white.opacity(0.08), in: Circle())
        }
        .buttonStyle(.plain)
        .help(help)
    }

    private var copyMenu: some View {
        Menu {
            Button("Copy") { app.copy(clip) }
            switch clip.kind {
            case .color:
                Button("Copy HEX") { app.copyTextVariant(colorValues.hex, for: clip) }
                Button("Copy RGB") { app.copyTextVariant(colorValues.rgb, for: clip) }
                Button("Copy HSL") { app.copyTextVariant(colorValues.hsl, for: clip) }
            case .image:
                if let ocr = clip.ocrText, !ocr.isEmpty {
                    Button("Copy recognized text") { app.copyTextVariant(ocr, for: clip) }
                }
            case .file, .multi:
                Button("Copy path") { app.copyTextVariant(clip.text, for: clip) }
            case .link:
                if let host = URL(string: clip.text.trimmingCharacters(in: .whitespacesAndNewlines))?.host {
                    Button("Copy domain") { app.copyTextVariant(host, for: clip) }
                }
            default:
                Button("Copy first line") { app.copyTextVariant(clip.title, for: clip) }
            }
        } label: {
            Label("Copy", systemImage: "doc.on.doc")
                .font(.system(size: 9, weight: .semibold))
                .foregroundStyle(.white.opacity(0.82))
                .padding(.horizontal, 9)
                .frame(height: 26)
                .background(Color.white.opacity(0.1), in: Capsule())
        }
        .menuStyle(.borderlessButton)
        .fixedSize()
    }

    @ViewBuilder
    private var inspectorContent: some View {
        switch clip.kind {
        case .color:
            colorInspector
        case .image:
            imageInspector(store.image(for: clip))
        case .file:
            fileInspector
        default:
            textInspector
        }
    }

    private var textInspector: some View {
        TextEditor(text: $draftText)
            .font(.system(size: 11, design: clip.kind == .code ? .monospaced : .default))
            .foregroundStyle(.white.opacity(0.88))
            .scrollContentBackground(.hidden)
            .padding(8)
            .background(Color.black.opacity(0.38), in: RoundedRectangle(cornerRadius: 11, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 11, style: .continuous)
                    .strokeBorder(isEditing ? Color(red: 0.20, green: 0.48, blue: 1).opacity(0.8) : Color.white.opacity(0.06), lineWidth: 1)
            }
            .disabled(!isEditing)
    }

    private var colorInspector: some View {
        HStack(spacing: 14) {
            Color(nsColor: clip.color ?? .gray)
                .frame(width: 330)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.12), lineWidth: 1)
                }

            VStack(alignment: .leading, spacing: 7) {
                colorValue("HEX", colorValues.hex)
                colorValue("RGB", colorValues.rgb)
                colorValue("CMYK", colorValues.cmyk)
                colorValue("HSL", colorValues.hsl)
                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func colorValue(_ label: String, _ value: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            Text(label)
                .font(.system(size: 8, weight: .semibold))
                .foregroundStyle(.white.opacity(0.35))
                .frame(width: 32, alignment: .leading)
            Text(value)
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .foregroundStyle(.white.opacity(0.82))
                .textSelection(.enabled)
        }
    }

    private func imageInspector(_ image: NSImage?) -> some View {
        HStack(spacing: 14) {
            Group {
                if let image {
                    Image(nsImage: image).resizable().aspectRatio(contentMode: .fit)
                } else {
                    Image(systemName: "photo").font(.system(size: 28)).foregroundStyle(.white.opacity(0.25))
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.black.opacity(0.35), in: RoundedRectangle(cornerRadius: 11, style: .continuous))

            VStack(alignment: .leading, spacing: 8) {
                detail("Size", clip.byteSize.formattedByteSize)
                if let image { detail("Dimensions", "\(Int(image.size.width)) × \(Int(image.size.height))") }
                detail("Source", clip.sourceAppName ?? "Unknown")
                if let ocr = clip.ocrText, !ocr.isEmpty {
                    Text(ocr)
                        .font(.system(size: 9))
                        .foregroundStyle(.white.opacity(0.48))
                        .lineLimit(5)
                }
                Spacer()
            }
            .frame(width: 240, alignment: .topLeading)
        }
    }

    private var fileInspector: some View {
        let path = clip.text.components(separatedBy: "\n").first ?? clip.text
        return HStack(spacing: 16) {
            Image(nsImage: NSWorkspace.shared.icon(forFile: path))
                .resizable().aspectRatio(contentMode: .fit)
                .frame(width: 74, height: 74)
                .padding(14)
                .background(Color.black.opacity(0.3), in: RoundedRectangle(cornerRadius: 13, style: .continuous))
            VStack(alignment: .leading, spacing: 8) {
                Text((path as NSString).lastPathComponent)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                detail("Size", clip.byteSize.formattedByteSize)
                detail("Path", path)
                Spacer()
            }
            Spacer()
        }
    }

    private func detail(_ label: String, _ value: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text(label.uppercased())
                .font(.system(size: 7, weight: .bold))
                .foregroundStyle(.white.opacity(0.3))
                .frame(width: 55, alignment: .leading)
            Text(value)
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(.white.opacity(0.68))
                .lineLimit(2)
                .textSelection(.enabled)
        }
    }

    private var isTextual: Bool { ![ClipKind.image, .file, .multi, .color].contains(clip.kind) }
    private var isEditable: Bool { [.text, .link, .code].contains(clip.kind) }
    private var wordCount: Int { clip.text.split { $0.isWhitespace }.count }

    private var colorValues: (hex: String, rgb: String, cmyk: String, hsl: String) {
        guard let color = clip.color?.usingColorSpace(.sRGB) else {
            return (clip.text.uppercased(), "—", "—", "—")
        }
        let r = color.redComponent
        let g = color.greenComponent
        let b = color.blueComponent
        let maxValue = max(r, g, b)
        let minValue = min(r, g, b)
        let delta = maxValue - minValue
        var hue: CGFloat = 0
        if delta > 0 {
            if maxValue == r { hue = 60 * (((g - b) / delta).truncatingRemainder(dividingBy: 6)) }
            else if maxValue == g { hue = 60 * (((b - r) / delta) + 2) }
            else { hue = 60 * (((r - g) / delta) + 4) }
        }
        if hue < 0 { hue += 360 }
        let lightness = (maxValue + minValue) / 2
        let saturation = delta == 0 ? 0 : delta / (1 - abs(2 * lightness - 1))
        let key = 1 - maxValue
        let denominator = max(0.0001, 1 - key)
        let cyan = (1 - r - key) / denominator
        let magenta = (1 - g - key) / denominator
        let yellow = (1 - b - key) / denominator
        return (
            clip.text.uppercased(),
            "rgb(\(Int(round(r * 255))), \(Int(round(g * 255))), \(Int(round(b * 255))))",
            "cmyk(\(Int(round(cyan * 100)))%, \(Int(round(magenta * 100)))%, \(Int(round(yellow * 100)))%, \(Int(round(key * 100)))%)",
            "hsl(\(Int(round(hue))), \(Int(round(saturation * 100)))%, \(Int(round(lightness * 100)))%)"
        )
    }
}

/// The reminder editor lives inside the expanded notch instead of opening a
/// second macOS window. This keeps the interaction attached to the selected clip.
private struct ShelfReminderPicker: View {
    let clip: Clip
    let onCancel: () -> Void
    let onSave: (Date) -> Void

    @EnvironmentObject private var app: AppState
    @State private var selectedDay: Date
    @State private var hour: Int
    @State private var minute: Int

    private let calendar = Calendar.current

    init(clip: Clip, onCancel: @escaping () -> Void, onSave: @escaping (Date) -> Void) {
        self.clip = clip
        self.onCancel = onCancel
        self.onSave = onSave
        let initial = clip.reminder?.fireDate ?? Date().addingTimeInterval(3_600)
        let calendar = Calendar.current
        _selectedDay = State(initialValue: calendar.startOfDay(for: initial))
        _hour = State(initialValue: calendar.component(.hour, from: initial))
        _minute = State(initialValue: calendar.component(.minute, from: initial) / 5 * 5)
    }

    var body: some View {
        VStack(spacing: 10) {
            header
            dayStrip
            timeRow
        }
    }

    private var header: some View {
        HStack(spacing: 10) {
            circleButton("xmark", action: onCancel)

            Spacer()

            VStack(spacing: 1) {
                Text("Pick date & time")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.white)
                Text(clip.title)
                    .font(.system(size: 8))
                    .foregroundStyle(.white.opacity(0.38))
                    .lineLimit(1)
                    .frame(maxWidth: 260)
            }

            Spacer()

            if clip.reminder != nil {
                Button("Remove") {
                    app.removeReminder(from: clip)
                    onCancel()
                }
                .buttonStyle(.plain)
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(.red.opacity(0.85))
            }

            circleButton("checkmark", prominent: true) {
                if let date = composedDate, date > Date() { onSave(date) }
            }
            .disabled(!isValid)
            .opacity(isValid ? 1 : 0.35)
        }
        .frame(height: 28)
    }

    private var dayStrip: some View {
        HStack(spacing: 6) {
            ForEach(Array(days.enumerated()), id: \.offset) { index, day in
                Button {
                    withAnimation(.spring(response: 0.24, dampingFraction: 0.82)) {
                        selectedDay = day
                    }
                } label: {
                    VStack(spacing: 2) {
                        Text(index == 0 ? "Today" : weekday(day))
                            .font(.system(size: 7, weight: .medium))
                            .foregroundStyle(.white.opacity(isSelected(day) ? 0.78 : 0.36))
                        Text(day.formatted(.dateTime.day()))
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(
                        isSelected(day)
                            ? Color(red: 0.18, green: 0.45, blue: 1)
                            : Color.black.opacity(0.28),
                        in: RoundedRectangle(cornerRadius: 10, style: .continuous)
                    )
                    .overlay {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .strokeBorder(Color.white.opacity(isSelected(day) ? 0.18 : 0.07), lineWidth: 1)
                    }
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var timeRow: some View {
        HStack(spacing: 8) {
            timeControl(value: hour, label: "HOUR", down: { hour = (hour + 23) % 24 }, up: { hour = (hour + 1) % 24 })

            Text(":")
                .font(.system(size: 17, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.28))

            timeControl(value: minute, label: "MINUTE", down: { minute = (minute + 55) % 60 }, up: { minute = (minute + 5) % 60 })
        }
    }

    private func timeControl(
        value: Int,
        label: String,
        down: @escaping () -> Void,
        up: @escaping () -> Void
    ) -> some View {
        HStack(spacing: 0) {
            Button(action: down) {
                Image(systemName: "minus").frame(width: 38, height: 40)
            }
            .buttonStyle(.plain)

            VStack(spacing: 0) {
                Text(String(format: "%02d", value))
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                Text(label)
                    .font(.system(size: 6, weight: .bold))
                    .foregroundStyle(.white.opacity(0.28))
            }
            .frame(maxWidth: .infinity)

            Button(action: up) {
                Image(systemName: "plus").frame(width: 38, height: 40)
            }
            .buttonStyle(.plain)
        }
        .font(.system(size: 9, weight: .semibold))
        .foregroundStyle(.white.opacity(0.7))
        .frame(maxWidth: .infinity)
        .frame(height: 43)
        .background(Color.black.opacity(0.28), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(Color.white.opacity(0.07), lineWidth: 1)
        }
    }

    private func circleButton(
        _ symbol: String,
        prominent: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(prominent ? .black : .white.opacity(0.62))
                .frame(width: 27, height: 27)
                .background(prominent ? Color.white : Color.white.opacity(0.08), in: Circle())
        }
        .buttonStyle(.plain)
    }

    private var days: [Date] {
        let today = calendar.startOfDay(for: Date())
        return (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: today) }
    }

    private var composedDate: Date? {
        calendar.date(bySettingHour: hour, minute: minute, second: 0, of: selectedDay)
    }

    private var isValid: Bool { composedDate.map { $0 > Date() } == true }

    private func isSelected(_ day: Date) -> Bool {
        calendar.isDate(day, inSameDayAs: selectedDay)
    }

    private func weekday(_ day: Date) -> String {
        day.formatted(.dateTime.weekday(.narrow))
    }
}

/// Compact alternative to the visual card shelf. It keeps the same click and
/// drag behaviour while making more of the history visible at once.
private struct ShelfListRow: View {
    let clip: Clip
    let index: Int

    @EnvironmentObject private var app: AppState
    @EnvironmentObject private var store: ClipStore
    @State private var isHovered = false

    private var isSelected: Bool { app.shelfInspectorClipID == clip.id }

    var body: some View {
        HStack(spacing: 9) {
            thumbnail
                .frame(width: 30, height: 30)
                .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))

            VStack(alignment: .leading, spacing: 2) {
                Text(clip.title)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.white.opacity(0.92))
                    .lineLimit(1)
                Text(clip.subtitle)
                    .font(.system(size: 9))
                    .foregroundStyle(.white.opacity(0.45))
                    .lineLimit(1)
            }

            Spacer(minLength: 4)

            if clip.reminder != nil {
                Image(systemName: "bell.fill")
                    .font(.system(size: 9))
                    .foregroundStyle(.yellow.opacity(0.9))
            }
            if clip.pinned {
                Image(systemName: "pin.fill")
                    .font(.system(size: 9))
                    .foregroundStyle(.orange.opacity(0.9))
            }
            if let shortcut = clip.shortcut {
                Text(shortcut)
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.55))
                    .padding(.horizontal, 5)
                    .padding(.vertical, 3)
                    .background(Color.white.opacity(0.09), in: Capsule())
            }
            if index < 10 {
                Text("⌃⌘\(index)")
                    .font(.system(size: 9, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.35))
            }
        }
        .padding(.horizontal, 9)
        .frame(height: 39)
        .background(Color.white.opacity(isHovered || isSelected ? 0.13 : 0.07), in: RoundedRectangle(cornerRadius: 9, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 9, style: .continuous)
                .strokeBorder(
                    isSelected ? Color(red: 0.20, green: 0.48, blue: 1) : Color.white.opacity(isHovered ? 0.22 : 0.08),
                    lineWidth: isSelected ? 2 : 1
                )
        }
        .contentShape(Rectangle())
        .scaleEffect(isHovered ? 1.01 : 1)
        .animation(.spring(response: 0.25, dampingFraction: 0.8), value: isHovered)
        .onHover { isHovered = $0 }
        .onTapGesture {
            if clip.kind == .color {
                app.copy(clip)
            }
            app.showShelfInspector(for: clip)
        }
        .onDrag { dragProvider() }
        .help(clip.title)
        .contextMenu {
            Button("Paste") { app.paste(clip) }
            Button("Copy") { app.copy(clip) }
            Button(clip.pinned ? "Unpin" : "Pin") { store.togglePin(clip) }
            ClipReminderMenu(clip: clip)
            Button("Delete", role: .destructive) { store.delete(clip) }
        }
    }

    @ViewBuilder
    private var thumbnail: some View {
        switch clip.kind {
        case .image:
            if let image = store.image(for: clip) {
                Image(nsImage: image).resizable().aspectRatio(contentMode: .fill)
            } else {
                iconTile
            }
        case .file:
            if let image = filePreviewImage {
                Image(nsImage: image).resizable().aspectRatio(contentMode: .fill)
            } else {
                Image(nsImage: NSWorkspace.shared.icon(forFile: firstPath))
                    .resizable().aspectRatio(contentMode: .fit).padding(4)
                    .background(Color.white.opacity(0.06))
            }
        case .color:
            Color(nsColor: clip.color ?? .gray)
        default:
            iconTile
        }
    }

    private var iconTile: some View {
        ZStack {
            Color.white.opacity(0.07)
            Image(systemName: clip.kind.symbol)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.white.opacity(0.48))
        }
    }

    private var firstPath: String {
        clip.text.components(separatedBy: "\n").first ?? clip.text
    }

    private var filePreviewImage: NSImage? {
        let extensions = ["png", "jpg", "jpeg", "heic", "tif", "tiff", "webp"]
        guard extensions.contains((firstPath as NSString).pathExtension.lowercased()) else { return nil }
        return NSImage(contentsOfFile: firstPath)
    }

    private func dragProvider() -> NSItemProvider {
        if clip.kind == .image, let url = store.imageURL(for: clip) {
            return NSItemProvider(contentsOf: url) ?? NSItemProvider(object: clip.text as NSString)
        }
        if clip.kind == .file {
            return NSItemProvider(contentsOf: URL(fileURLWithPath: firstPath))
                ?? NSItemProvider(object: clip.text as NSString)
        }
        return NSItemProvider(object: clip.text as NSString)
    }
}

/// A card on the shelf: preview across the whole face, context along the bottom.
struct ShelfCard: View {
    let clip: Clip
    let index: Int

    @EnvironmentObject private var app: AppState
    @EnvironmentObject private var store: ClipStore
    @State private var isHovered = false
    /// A short press-in on tap. The card is about to disappear from under the
    /// cursor as the paste lands, so the feedback has to happen immediately.
    @State private var isPressed = false
    /// Drives the staggered entrance when the shelf comes down.
    @State private var hasAppeared = false

    private var isSelected: Bool { app.shelfInspectorClipID == clip.id }

    var body: some View {
        ZStack(alignment: .bottom) {
            preview
            footer
        }
        .frame(width: Theme.shelfCardSize.width, height: Theme.shelfCardSize.height)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(
                    isSelected ? Color(red: 0.20, green: 0.48, blue: 1) : Color.white.opacity(isHovered ? 0.25 : 0.08),
                    lineWidth: isSelected ? 2.5 : 1
                )
        }
        .overlay(alignment: .topLeading) { shortcutBadge }
        .overlay(alignment: .topTrailing) { hoverActions }
        .overlay { confirmation }
        .scaleEffect(hasAppeared ? (isPressed ? 0.94 : (isHovered ? 1.02 : 1)) : 0.92, anchor: .top)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: app.confirmedClipID)
        .opacity(hasAppeared ? 1 : 0)
        .offset(y: hasAppeared ? 0 : -14)
        .animation(.easeOut(duration: 0.12), value: isHovered)
        .onAppear(perform: animateIn)
        .onChange(of: app.isShelfVisible) { _, visible in
            if visible { animateIn() } else { scheduleReset() }
        }
        .onHover { isHovered = $0 }
        .onTapGesture {
            withAnimation(.easeOut(duration: 0.09)) { isPressed = true }
            withAnimation(.spring(response: 0.3, dampingFraction: 0.55).delay(0.09)) {
                isPressed = false
            }
            if clip.kind == .color {
                app.copy(clip)
            }
            app.showShelfInspector(for: clip)
        }
        .onDrag { dragProvider() }
        .help(clip.title)
        .contextMenu {
            Button("Paste") { app.paste(clip) }
            Button("Copy") { app.copy(clip) }
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

            Button("Delete", role: .destructive) { store.delete(clip) }
        }
    }

    // MARK: - Preview

    @ViewBuilder
    private var preview: some View {
        switch clip.kind {
        case .image:
            if let image = store.image(for: clip) {
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: Theme.shelfCardSize.width, height: Theme.shelfCardSize.height)
            } else {
                symbolTile
            }

        case .color:
            ZStack(alignment: .bottomLeading) {
                Color(nsColor: clip.color ?? .gray)
                Text(clip.text.uppercased())
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                    .shadow(radius: 2)
                    .padding(.leading, 10)
                    .padding(.bottom, 26)
            }

        case .file:
            if let image = filePreviewImage {
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: Theme.shelfCardSize.width, height: Theme.shelfCardSize.height)
            } else {
                VStack(spacing: 6) {
                    Image(nsImage: NSWorkspace.shared.icon(forFile: firstPath))
                        .resizable()
                        .frame(width: 30, height: 30)
                    Text((firstPath as NSString).lastPathComponent)
                        .font(.system(size: 10))
                        .foregroundStyle(.white.opacity(0.8))
                        .lineLimit(1)
                        .padding(.horizontal, 8)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.white.opacity(0.06))
            }

        default:
            Text(clip.text)
                .font(.system(size: 11, design: clip.kind == .code ? .monospaced : .default))
                .foregroundStyle(.white.opacity(0.9))
                .lineLimit(4)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .padding(10)
                .padding(.bottom, 18)
                .background(Color.white.opacity(0.06))
        }
    }

    private var symbolTile: some View {
        Image(systemName: clip.kind.symbol)
            .font(.system(size: 18))
            .foregroundStyle(.white.opacity(0.3))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.white.opacity(0.06))
    }

    // MARK: - Footer

    private var footer: some View {
        HStack(spacing: 5) {
            if let icon = AppIconProvider.icon(forBundleID: clip.sourceBundleID) {
                Image(nsImage: icon).resizable().frame(width: 13, height: 13)
            }
            Text(clip.createdAt.relativeShort)
                .font(.system(size: 9))
            Spacer(minLength: 4)
            if clip.kind == .image || clip.kind == .file, clip.byteSize > 0 {
                Text(clip.byteSize.formattedByteSize)
                    .font(.system(size: 9))
            }
        }
        .foregroundStyle(.white.opacity(0.7))
        .padding(.horizontal, 8)
        .padding(.bottom, 6)
        .frame(maxWidth: .infinity)
        // A gradient under the footer: without it the text vanishes over light images.
        .background(
            LinearGradient(
                colors: [.black.opacity(0), .black.opacity(0.75)],
                startPoint: .top, endPoint: .bottom
            )
            .frame(height: 34)
            .allowsHitTesting(false),
            alignment: .bottom
        )
    }

    @ViewBuilder
    private var shortcutBadge: some View {
        if index < 10, isHovered || isSelected {
            Text("⌃⌘\(index)")
                .font(.system(size: 8, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
                .padding(.horizontal, 5)
                .padding(.vertical, 3)
                .background(Color.black.opacity(0.6), in: Capsule())
                .padding(5)
        }
    }

    @ViewBuilder
    private var hoverActions: some View {
        if isHovered || isSelected {
            HStack(spacing: 4) {
                cardAction("eye") { app.showShelfInspector(for: clip) }
                cardAction(clip.pinned ? "pin.fill" : "pin") { store.togglePin(clip) }
                cardAction("trash", destructive: true) {
                    if isSelected { app.closeShelfInspector() }
                    store.delete(clip)
                }
            }
            .padding(5)
            .transition(.opacity.combined(with: .scale(scale: 0.9, anchor: .topTrailing)))
        }
    }

    private func cardAction(
        _ symbol: String,
        destructive: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 8, weight: .semibold))
                .foregroundStyle(destructive ? Color.closeRed : .white)
                .frame(width: 21, height: 21)
                .background(Color.black.opacity(0.62), in: Circle())
        }
        .buttonStyle(.plain)
    }

    /// The card says what just happened to it, in place. Pressed cards are what
    /// the eye is already on, so this is where the answer is looked for.
    @ViewBuilder
    private var confirmation: some View {
        if app.confirmedClipID == clip.id {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.black.opacity(0.6))
                VStack(spacing: 5) {
                    Image(systemName: "checkmark")
                        .font(.system(size: 17, weight: .semibold))
                    Text(app.flashLabel)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(.white.opacity(0.75))
                }
                .foregroundStyle(.white)
            }
            .transition(.opacity.combined(with: .scale(scale: 0.88)))
        }
    }

    /// Cards enter one after another, following the shelf down.
    ///
    /// The delay is capped: past the first handful the eye has already read the
    /// motion, and letting it grow would leave the last cards trailing after the
    /// shelf has clearly finished arriving.
    private func animateIn() {
        guard !hasAppeared else { return }
        let delay = min(Double(index), 7) * 0.035
        withAnimation(.spring(response: 0.36, dampingFraction: 0.8).delay(delay)) {
            hasAppeared = true
        }
    }

    /// Reset only once the shelf has finished retracting — clearing the cards
    /// right away would show the shelf sliding up empty.
    private func scheduleReset() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.32) {
            guard !app.isShelfVisible else { return }
            hasAppeared = false
        }
    }

    private var firstPath: String {
        clip.text.components(separatedBy: "\n").first ?? clip.text
    }

    private var filePreviewImage: NSImage? {
        let extensions = ["png", "jpg", "jpeg", "heic", "tif", "tiff", "webp"]
        guard extensions.contains((firstPath as NSString).pathExtension.lowercased()) else { return nil }
        return NSImage(contentsOfFile: firstPath)
    }

    private func dragProvider() -> NSItemProvider {
        if clip.kind == .image, let url = store.imageURL(for: clip) {
            return NSItemProvider(contentsOf: url) ?? NSItemProvider(object: clip.text as NSString)
        }
        if clip.kind == .file {
            return NSItemProvider(contentsOf: URL(fileURLWithPath: firstPath))
                ?? NSItemProvider(object: clip.text as NSString)
        }
        return NSItemProvider(object: clip.text as NSString)
    }
}
