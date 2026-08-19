import AppKit
import SwiftUI

/// The quick search window (⌃⌘V): type, pick with the arrows, Enter pastes.
struct QuickSearchView: View {
    @EnvironmentObject private var app: AppState
    /// Observed directly: a change in the history must redraw this at once.
    @EnvironmentObject private var store: ClipStore
    @EnvironmentObject private var preferences: Preferences
    @State private var query = ""
    @State private var selectedIndex = 0
    @State private var kindFilter: ClipKind?
    @State private var categoryFilter: String?
    @FocusState private var searchFocused: Bool
    @Namespace private var selectionNamespace

    private var results: [Clip] {
        store.clips(matching: query, kind: kindFilter, category: categoryFilter)
    }

    var body: some View {
        VStack(spacing: 0) {
            searchField
            Divider().opacity(0.5)
            filterBar
            Divider().opacity(0.5)
            resultList
            footer
        }
        .frame(width: Theme.panelWidth, height: Theme.panelHeight)
        .panelChrome()
        .onAppear {
            searchFocused = true
            selectedIndex = 0
        }
        // Arrows move the selection without pulling focus out of the search field.
        .onKeyPress(.upArrow) { move(by: -1); return .handled }
        .onKeyPress(.downArrow) { move(by: 1); return .handled }
        .onKeyPress(.return, phases: .down) { press in
            activateSelection(inverted: press.modifiers.contains(.command))
            return .handled
        }
        .onKeyPress(.escape) { app.hideQuickSearch(); return .handled }
    }

    // MARK: - Sections

    private var searchField: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            TextField("Search everything you've copied…", text: $query)
                .textFieldStyle(.plain)
                .font(.system(size: 16))
                .focused($searchFocused)
                .onChange(of: query) { _, _ in selectedIndex = 0 }
        }
        .padding(.horizontal, 16)
        .frame(height: 52)
    }

    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                filterChip(title: "All", kind: nil)
                ForEach(ClipKind.allCases, id: \.self) { kind in
                    filterChip(title: kind.label, kind: kind)
                }

                if !store.categories.isEmpty {
                    Divider().frame(height: 16).padding(.horizontal, 2)
                    ForEach(store.categories, id: \.self) { category in
                        categoryChip(category)
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
    }

    private func filterChip(title: String, kind: ClipKind?) -> some View {
        let isActive = kindFilter == kind
        return Button {
            kindFilter = kind
            selectedIndex = 0
        } label: {
            HStack(spacing: 4) {
                if let kind { Image(systemName: kind.symbol).font(.system(size: 10)) }
                Text(title).font(.system(size: 11, weight: .medium))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(
                Capsule().fill(isActive ? Color.accentColor.opacity(0.9) : Color.primary.opacity(0.06))
            )
            .foregroundStyle(isActive ? Color.white : Color.primary)
        }
        .buttonStyle(.plain)
    }

    private func categoryChip(_ category: String) -> some View {
        let isActive = categoryFilter == category
        return Button {
            // Pressing the same collection again clears the filter.
            categoryFilter = isActive ? nil : category
            selectedIndex = 0
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "folder").font(.system(size: 10))
                Text(category).font(.system(size: 11, weight: .medium))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(
                Capsule().fill(isActive ? Color.accentColor.opacity(0.9) : Color.primary.opacity(0.06))
            )
            .foregroundStyle(isActive ? Color.white : Color.primary)
        }
        .buttonStyle(.plain)
    }

    private var resultList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 2) {
                    ForEach(Array(results.enumerated()), id: \.element.id) { index, clip in
                        ClipRowView(
                            clip: clip,
                            isSelected: index == selectedIndex,
                            namespace: selectionNamespace
                        )
                            .id(clip.id)
                            .onTapGesture { app.activate(clip) }
                            .contextMenu { contextMenu(for: clip) }
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .animation(.spring(response: 0.26, dampingFraction: 0.82), value: selectedIndex)
            }
            .onChange(of: selectedIndex) { _, index in
                guard index < results.count else { return }
                withAnimation(.easeOut(duration: 0.12)) {
                    proxy.scrollTo(results[index].id, anchor: .center)
                }
            }
            .overlay {
                if results.isEmpty { emptyState }
            }
        }
        .frame(maxHeight: .infinity)
    }

    private var emptyState: some View {
        VStack(spacing: 6) {
            Image(systemName: query.isEmpty ? "doc.on.clipboard" : "magnifyingglass")
                .font(.system(size: 26))
                .foregroundStyle(.tertiary)
            Text(query.isEmpty ? "Nothing copied yet — it shows up here."
                               : "No match for \"\(query)\"")
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
        }
    }

    private var footer: some View {
        HStack(spacing: 14) {
            hint("↩", preferences.clickActivation == .copy ? "copy" : "paste")
            hint("⌘↩", preferences.clickActivation == .copy ? "paste" : "copy")
            hint("↑↓", "navigate")
            hint("esc", "close")
            Spacer()
            Text("\(results.count) \(results.count == 1 ? "clip" : "clips")")
                .font(.system(size: 10))
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, 14)
        .frame(height: 32)
        .background(Color.primary.opacity(0.03))
    }

    private func hint(_ key: String, _ label: String) -> some View {
        HStack(spacing: 4) {
            Text(key)
                .font(.system(size: 10, weight: .semibold, design: .rounded))
                .padding(.horizontal, 5)
                .padding(.vertical, 2)
                .background(Color.primary.opacity(0.09), in: RoundedRectangle(cornerRadius: 4))
            Text(label)
                .font(.system(size: 10))
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private func contextMenu(for clip: Clip) -> some View {
        Button("Paste") { app.paste(clip) }
        Button("Copy") { app.copy(clip) }
        Divider()
        Button(clip.pinned ? "Unpin" : "Pin") { store.togglePin(clip) }
        ClipReminderMenu(clip: clip)
        Button("Delete", role: .destructive) { store.delete(clip) }
    }

    // MARK: - Keyboard

    private func move(by delta: Int) {
        guard !results.isEmpty else { return }
        selectedIndex = min(max(selectedIndex + delta, 0), results.count - 1)
    }

    private func activateSelection(inverted: Bool = false) {
        guard selectedIndex < results.count else { return }
        app.activate(results[selectedIndex], inverted: inverted)
    }
}
