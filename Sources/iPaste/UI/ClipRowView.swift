import AppKit
import SwiftUI

/// One row of results: icon or preview, title, context.
struct ClipRowView: View {
    let clip: Clip
    var isSelected: Bool
    /// Shared with the list so the highlight travels between rows.
    var namespace: Namespace.ID

    @EnvironmentObject private var app: AppState
    /// Observed directly: a change in the history must redraw this at once.
    @EnvironmentObject private var store: ClipStore

    var body: some View {
        HStack(spacing: 12) {
            preview
                .frame(width: 36, height: 36)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

            VStack(alignment: .leading, spacing: 2) {
                Text(clip.title)
                    .lineLimit(1)
                    .font(.system(size: 13, weight: .medium))
                Text(clip.subtitle)
                    .lineLimit(1)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 8)

            if clip.reminder != nil {
                Image(systemName: "bell.fill")
                    .font(.system(size: 10))
                    .foregroundStyle(Color.accentColor)
            }
            if clip.pinned {
                Image(systemName: "pin.fill")
                    .font(.system(size: 10))
                    .foregroundStyle(.orange)
                    .transition(.scale(scale: 0.4).combined(with: .opacity))
            }
            if let shortcut = clip.shortcut {
                Text(shortcut)
                    .font(.system(size: 10, design: .monospaced))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.primary.opacity(0.08), in: Capsule())
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 12)
        .frame(height: Theme.rowHeight)
        .background {
            if isSelected {
                RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous)
                    .fill(Color.accentColor.opacity(0.18))
                    .matchedGeometryEffect(id: "selectedRow", in: namespace)
            }
        }
        .contentShape(Rectangle())
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: clip.pinned)
    }

    @ViewBuilder
    private var preview: some View {
        switch clip.kind {
        case .image:
            if let image = store.image(for: clip) {
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                iconTile
            }
        case .color:
            ZStack {
                Color(nsColor: clip.color ?? .gray)
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .strokeBorder(Color.primary.opacity(0.15), lineWidth: 1)
            }
        case .file:
            Image(nsImage: NSWorkspace.shared.icon(forFile: clip.text.components(separatedBy: "\n")[0]))
                .resizable()
                .aspectRatio(contentMode: .fit)
                .padding(2)
        default:
            iconTile
        }
    }

    private var iconTile: some View {
        ZStack {
            Color.primary.opacity(0.07)
            Image(systemName: clip.kind.symbol)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.secondary)
        }
    }
}
