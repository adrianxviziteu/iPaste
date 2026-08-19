import AppKit
import SwiftUI

// MARK: - 1. Welcome

/// The menu bar with the menu open: exactly where the app lives. The first step
/// answers where is it, not does it not look nice.
struct WelcomeHero: View {
    var body: some View {
        VStack(spacing: 0) {
            menuBar
            menu
                .padding(.trailing, 26)
        }
        .frame(width: 320)
    }

    private var menuBar: some View {
        HStack(spacing: 13) {
            Spacer(minLength: 0)
            ForEach(["wifi", "battery.75percent", "magnifyingglass"], id: \.self) { symbol in
                Image(systemName: symbol)
                    .font(.system(size: 10))
                    .foregroundStyle(.tertiary)
            }
            Image(systemName: "doc.on.clipboard")
                .font(.system(size: 10))
                .foregroundStyle(.primary)
                .padding(3)
                .background {
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(Color.accentColor.opacity(0.22))
                }
            Text("09:41")
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 12)
        .frame(height: 24)
        .background(OnboardingStyle.surface)
        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
    }

    private var menu: some View {
        VStack(alignment: .leading, spacing: 0) {
            menuItem("Quick Search…", keys: "⌃⌘V")
            menuItem("Show Shelf", keys: "⌃⌘S")

            Divider().padding(.vertical, 4)

            ForEach(["Invoice #2291 — paid", "stripe.com/invoices", "#1D6FE0"], id: \.self) { title in
                menuItem(title, keys: nil, dimmed: true)
            }
        }
        .padding(.vertical, 6)
        .frame(width: 214, alignment: .leading)
        .mockChrome()
        .padding(.top, 7)
    }

    private func menuItem(_ title: String, keys: String?, dimmed: Bool = false) -> some View {
        HStack(spacing: 8) {
            Text(title)
                .font(.system(size: 11))
                .foregroundStyle(dimmed ? .secondary : .primary)
                .lineLimit(1)
            Spacer(minLength: 6)
            if let keys {
                Text(keys)
                    .font(.system(size: 10))
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.horizontal, 11)
        .frame(height: 21)
    }
}

// MARK: - 2. Capture

/// A real history: every row is a capture with its recognized kind beside it.
/// The step is about classification, so classification is what is shown — not six
/// colored icons.
struct CaptureHero: View {
    private struct Row {
        let kind: ClipKind
        let title: String
        let source: String
    }

    private let rows: [Row] = [
        Row(kind: .link, title: "stripe.com/invoices/2291", source: "Safari"),
        Row(kind: .code, title: "let tokens = DesignTokens.load()", source: "Xcode"),
        Row(kind: .color, title: "#1D6FE0", source: "Figma"),
        Row(kind: .image, title: "Screenshot 2026-08-19", source: "Preview")
    ]

    var body: some View {
        VStack(spacing: 0) {
            ForEach(Array(rows.enumerated()), id: \.offset) { index, row in
                if index > 0 { Divider().opacity(0.5) }
                self.row(row)
            }
        }
        .frame(width: 340)
        .mockChrome()
    }

    private func row(_ row: Row) -> some View {
        HStack(spacing: 10) {
            Image(systemName: row.kind.symbol)
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
                .frame(width: 26, height: 26)
                .background {
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(OnboardingStyle.surface)
                }

            Text(row.title)
                .font(.system(size: 11, design: row.kind == .code ? .monospaced : .default))
                .lineLimit(1)

            Spacer(minLength: 8)

            Text(row.kind.label)
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Capsule().fill(OnboardingStyle.surface))

            Text(row.source)
                .font(.system(size: 9))
                .foregroundStyle(.tertiary)
                .frame(width: 44, alignment: .leading)
        }
        .padding(.horizontal, 12)
        .frame(height: 42)
    }
}

// MARK: - 3. Quick search

/// A mockup of the quick search window with one row selected. The accent appears
/// exactly once — on the selection, because there it means something.
struct SearchHero: View {
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                Text("invoice")
                    .font(.system(size: 12))
                Spacer(minLength: 0)
                Text("3 clips")
                    .font(.system(size: 10))
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 12)
            .frame(height: 34)

            Divider().opacity(0.5)

            VStack(spacing: 2) {
                row("doc.on.clipboard", "Invoice #2291 — paid", "Text · Mail · 4m", selected: true)
                row("link", "stripe.com/invoices/2291", "Links · Safari · 6m")
                row("photo", "Receipt screenshot", "Images · Preview · 20m")
            }
            .padding(6)
        }
        .frame(width: 330)
        .mockChrome(cornerRadius: 12)
    }

    private func row(_ symbol: String, _ title: String, _ subtitle: String, selected: Bool = false) -> some View {
        HStack(spacing: 9) {
            Image(systemName: symbol)
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
                .frame(width: 24, height: 24)
                .background {
                    RoundedRectangle(cornerRadius: 5, style: .continuous)
                        .fill(OnboardingStyle.surface)
                }

            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.system(size: 11, weight: .medium))
                    .lineLimit(1)
                Text(subtitle)
                    .font(.system(size: 9))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 4)

            if selected {
                KeyCap(label: "↩", size: 9)
            }
        }
        .padding(.horizontal, 7)
        .frame(height: 36)
        .background {
            RoundedRectangle(cornerRadius: 7, style: .continuous)
                .fill(selected ? Color.accentColor.opacity(0.16) : .clear)
        }
    }
}

// MARK: - 4. Shelf

/// The shelf as it really looks: black, hanging from the top edge, rounded only
/// below. The black is not decoration here — it is the shelf actual color.
struct ShelfHero: View {
    @State private var out = false

    var body: some View {
        ZStack(alignment: .top) {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(OnboardingStyle.surface)
                .overlay(alignment: .top) {
                    Rectangle()
                        .fill(Color.primary.opacity(0.07))
                        .frame(height: 16)
                }
                .overlay {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(OnboardingStyle.hairline, lineWidth: 1)
                }

            BottomRoundedRectangle(radius: 6)
                .fill(.black)
                .frame(width: 88, height: 16)
                .opacity(out ? 0 : 1)

            shelf
                .offset(y: out ? 0 : -96)
        }
        .frame(width: 330, height: 186)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .shadow(color: .black.opacity(0.12), radius: 12, y: 4)
        .onAppear {
            // One drop, on entering the step: the gesture reads immediately, and
            // looping it forever would pull the eye while the text is being read.
            withAnimation(.spring(response: 0.5, dampingFraction: 0.82).delay(0.35)) {
                out = true
            }
        }
    }

    private var shelf: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack(spacing: 6) {
                Capsule()
                    .fill(.white.opacity(0.10))
                    .frame(width: 104, height: 17)
                    .overlay(alignment: .leading) {
                        Text("Search…")
                            .font(.system(size: 8))
                            .foregroundStyle(.white.opacity(0.35))
                            .padding(.leading, 8)
                    }
                Spacer(minLength: 0)
                ForEach(0..<3, id: \.self) { _ in
                    Circle().fill(.white.opacity(0.10)).frame(width: 17, height: 17)
                }
            }

            HStack(spacing: 6) {
                ForEach(0..<4, id: \.self) { index in
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(.white.opacity(0.07))
                        .frame(width: 60, height: 44)
                        .overlay {
                            Image(systemName: ["link", "photo", "text.alignleft", "doc"][index])
                                .font(.system(size: 12))
                                .foregroundStyle(.white.opacity(0.45))
                        }
                        .overlay {
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .strokeBorder(.white.opacity(0.09), lineWidth: 1)
                        }
                }
            }
        }
        .padding(.horizontal, 13)
        .padding(.top, 11)
        .frame(width: 278, height: 96, alignment: .top)
        .background(Color.black)
        .clipShape(BottomRoundedRectangle(radius: 14))
    }
}

// MARK: - 5. Library

/// A mockup of the full window: the same three columns as `LibraryView`.
struct LibraryHero: View {
    var body: some View {
        HStack(spacing: 0) {
            sidebar
            Divider().opacity(0.5)
            grid
            Divider().opacity(0.5)
            inspector
        }
        .frame(width: 386, height: 186)
        .overlay(alignment: .top) { titleBar }
        .mockChrome()
    }

    private var titleBar: some View {
        HStack(spacing: 5) {
            ForEach(0..<3, id: \.self) { _ in
                Circle().fill(Color.primary.opacity(0.16)).frame(width: 6, height: 6)
            }
            Spacer()
            Text("iPaste Library")
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(.secondary)
            Spacer()
            Color.clear.frame(width: 28, height: 1)
        }
        .padding(.horizontal, 9)
        .frame(height: 22)
    }

    private var sidebar: some View {
        VStack(alignment: .leading, spacing: 2) {
            label("LIBRARY")
            item("tray.full", "All", selected: true)
            item("pin", "Pinned")
            label("COLLECTIONS")
            item("folder", "Design")
            item("folder", "Snippets")
        }
        .padding(.horizontal, 7)
        .padding(.top, 27)
        .frame(width: 96, alignment: .top)
        .frame(maxHeight: .infinity, alignment: .top)
        .background(OnboardingStyle.surface)
    }

    private func label(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 7, weight: .semibold))
            .foregroundStyle(.tertiary)
            .padding(.top, 6)
            .padding(.leading, 4)
    }

    private func item(_ symbol: String, _ title: String, selected: Bool = false) -> some View {
        HStack(spacing: 5) {
            Image(systemName: symbol)
                .font(.system(size: 8))
                .foregroundStyle(.secondary)
                .frame(width: 10)
            Text(title)
                .font(.system(size: 9))
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 5)
        .frame(height: 17)
        .background {
            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .fill(selected ? Color.accentColor.opacity(0.16) : .clear)
        }
    }

    private var grid: some View {
        VStack(spacing: 0) {
            HStack(spacing: 5) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 8))
                    .foregroundStyle(.tertiary)
                Text("Search the library…")
                    .font(.system(size: 8))
                    .foregroundStyle(.tertiary)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 9)
            .frame(height: 25)

            Divider().opacity(0.5)

            LazyVGrid(
                columns: Array(repeating: GridItem(.fixed(54), spacing: 6), count: 3),
                spacing: 6
            ) {
                ForEach(0..<6, id: \.self) { index in
                    RoundedRectangle(cornerRadius: 5, style: .continuous)
                        .fill(OnboardingStyle.surface)
                        .frame(height: 42)
                        .overlay {
                            RoundedRectangle(cornerRadius: 5, style: .continuous)
                                .strokeBorder(
                                    index == 1 ? Color.accentColor.opacity(0.7) : OnboardingStyle.hairline,
                                    lineWidth: 1
                                )
                        }
                }
            }
            .padding(9)

            Spacer(minLength: 0)
        }
        .padding(.top, 22)
        .frame(width: 194)
    }

    private var inspector: some View {
        VStack(alignment: .leading, spacing: 7) {
            RoundedRectangle(cornerRadius: 5, style: .continuous)
                .fill(OnboardingStyle.surface)
                .frame(height: 48)
                .overlay {
                    RoundedRectangle(cornerRadius: 5, style: .continuous)
                        .strokeBorder(OnboardingStyle.hairline, lineWidth: 1)
                }

            ForEach(0..<4, id: \.self) { line in
                Capsule()
                    .fill(Color.primary.opacity(line == 0 ? 0.20 : 0.09))
                    .frame(width: [70, 58, 62, 42][line], height: 4)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 9)
        .padding(.top, 27)
        .padding(.bottom, 10)
        .frame(width: 94, alignment: .leading)
    }
}

// MARK: - 6. Permission

/// The row in System Settings the user is looking for, and what happens once it
/// is ticked. More use than a drawn shield.
struct PermissionHero: View {
    let granted: Bool

    var body: some View {
        VStack(spacing: 14) {
            VStack(spacing: 0) {
                header
                Divider().opacity(0.5)
                appRow
            }
            .frame(width: 300)
            .mockChrome()

            HStack(spacing: 9) {
                KeyCap(label: "⌘")
                KeyCap(label: "V")
                Image(systemName: "arrow.right")
                    .font(.system(size: 9))
                    .foregroundStyle(.tertiary)
                Text("sent to the app you were in")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }
            .opacity(granted ? 1 : 0.45)
        }
    }

    private var header: some View {
        HStack(spacing: 7) {
            Image(systemName: "accessibility")
                .font(.system(size: 10))
                .foregroundStyle(.secondary)
            Text("Privacy & Security › Accessibility")
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(.secondary)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 11)
        .frame(height: 28)
        .background(OnboardingStyle.surface)
    }

    private var appRow: some View {
        HStack(spacing: 9) {
            Image(systemName: "doc.on.clipboard")
                .font(.system(size: 12))
                .foregroundStyle(.primary)
                .frame(width: 24, height: 24)
                .background {
                    RoundedRectangle(cornerRadius: 5, style: .continuous)
                        .fill(OnboardingStyle.surface)
                }

            Text("iPaste")
                .font(.system(size: 12, weight: .medium))

            Spacer(minLength: 0)

            // A drawn switch, not a working one: this is a picture of what they will see.
            Capsule()
                .fill(granted ? Color.green : Color.primary.opacity(0.16))
                .frame(width: 30, height: 18)
                .overlay(alignment: granted ? .trailing : .leading) {
                    Circle()
                        .fill(.white)
                        .frame(width: 14, height: 14)
                        .shadow(color: .black.opacity(0.2), radius: 1, y: 0.5)
                        .padding(.horizontal, 2)
                }
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: granted)
        }
        .padding(.horizontal, 11)
        .frame(height: 44)
    }
}

// MARK: - 7. Ready

/// No flourish on the last step: the app is ready, and it is clear where it sits.
struct ReadyHero: View {
    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: "checkmark.circle")
                .font(.system(size: 40, weight: .light))
                .foregroundStyle(Color.accentColor)

            HStack(spacing: 7) {
                Image(systemName: "arrow.up")
                    .font(.system(size: 10))
                    .foregroundStyle(.tertiary)
                Text("iPaste is in the menu bar, top right")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }
        }
    }
}
