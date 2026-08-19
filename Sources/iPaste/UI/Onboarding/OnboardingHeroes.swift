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

            ForEach(["Invoice #2291", "stripe.com/invoices", "#1D6FE0"], id: \.self) { title in
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
                row("doc.on.clipboard", "Invoice #2291", "Text · Mail · 4m", selected: true)
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
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(OnboardingStyle.surface)
                .overlay(alignment: .top) {
                    Rectangle()
                        .fill(Color.primary.opacity(0.07))
                        .frame(height: 16)
                }
                .overlay {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
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
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
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
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(.white.opacity(0.07))
                        .frame(width: 60, height: 44)
                        .overlay {
                            Image(systemName: ["link", "photo", "text.alignleft", "doc"][index])
                                .font(.system(size: 12))
                                .foregroundStyle(.white.opacity(0.45))
                        }
                        .overlay {
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .strokeBorder(.white.opacity(0.09), lineWidth: 1)
                        }
                }
            }
        }
        .padding(.horizontal, 13)
        .padding(.top, 11)
        .frame(width: 278, height: 96, alignment: .top)
        .background(Color.black)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

// MARK: - 5. Library

/// The current product has no separate Library window. Selection expands the
/// notch itself and reveals the contextual inspector under the card shelf.
struct LibraryHero: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 5) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 8))
                    .foregroundStyle(.white.opacity(0.34))
                Text("Search…")
                    .font(.system(size: 8))
                    .foregroundStyle(.white.opacity(0.34))
                Spacer(minLength: 0)
                Circle().fill(Color.white.opacity(0.1)).frame(width: 16, height: 16)
                Circle().fill(Color.white.opacity(0.1)).frame(width: 16, height: 16)
            }
            .padding(.horizontal, 3)

            HStack(spacing: 7) {
                card("#1D6FE0", color: OnboardingStyle.accent, selected: true)
                card("Invoice #2291", symbol: "text.alignleft")
                card("Receipt.png", symbol: "photo")
                card("stripe.com", symbol: "link")
            }

            VStack(alignment: .leading, spacing: 7) {
                HStack {
                    Label("Color", systemImage: "paintpalette")
                        .font(.system(size: 8, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.58))
                    Spacer()
                    Text("HEX")
                        .font(.system(size: 7, weight: .bold))
                        .foregroundStyle(.white.opacity(0.3))
                    Text("#1D6FE0")
                        .font(.system(size: 9, weight: .semibold, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.82))
                    ForEach(["bell", "doc.on.doc", "xmark"], id: \.self) { symbol in
                        Image(systemName: symbol)
                            .font(.system(size: 7, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.65))
                            .frame(width: 18, height: 18)
                            .background(Color.white.opacity(0.08), in: Circle())
                    }
                }

                HStack(spacing: 9) {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(OnboardingStyle.accent)
                        .frame(width: 155, height: 48)

                    VStack(alignment: .leading, spacing: 4) {
                        value("RGB", "rgb(29, 111, 224)")
                        value("HSL", "hsl(214, 77%, 50%)")
                    }
                    Spacer()
                }
            }
            .padding(9)
            .background(Color.white.opacity(0.052), in: RoundedRectangle(cornerRadius: 11, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 11, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.09), lineWidth: 1)
            }
        }
        .padding(12)
        .frame(width: 420, height: 210, alignment: .top)
        .background(Color.black)
        .clipShape(BottomRoundedRectangle(radius: 20))
        .overlay {
            BottomRoundedRectangle(radius: 20)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.48), radius: 22, y: 12)
    }

    private func card(_ title: String, symbol: String? = nil, color: Color? = nil, selected: Bool = false) -> some View {
        RoundedRectangle(cornerRadius: 8, style: .continuous)
            .fill(color ?? Color.white.opacity(0.065))
            .frame(width: 92, height: 54)
            .overlay {
                if let symbol {
                    Image(systemName: symbol)
                        .font(.system(size: 12))
                        .foregroundStyle(.white.opacity(0.45))
                }
            }
            .overlay(alignment: .bottomLeading) {
                Text(title)
                    .font(.system(size: 7, weight: .medium))
                    .foregroundStyle(.white.opacity(0.78))
                    .lineLimit(1)
                    .padding(6)
            }
            .overlay {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .strokeBorder(
                        selected ? OnboardingStyle.accent : Color.white.opacity(0.08),
                        lineWidth: selected ? 2 : 1
                    )
            }
    }

    private func value(_ label: String, _ text: String) -> some View {
        HStack(spacing: 7) {
            Text(label)
                .font(.system(size: 6, weight: .bold))
                .foregroundStyle(.white.opacity(0.28))
                .frame(width: 23, alignment: .leading)
            Text(text)
                .font(.system(size: 7, weight: .medium, design: .monospaced))
                .foregroundStyle(.white.opacity(0.65))
        }
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

            if !granted {
                Text("TURN ON")
                    .font(.system(size: 7, weight: .bold))
                    .tracking(0.8)
                    .foregroundStyle(OnboardingStyle.accent)
            }
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
