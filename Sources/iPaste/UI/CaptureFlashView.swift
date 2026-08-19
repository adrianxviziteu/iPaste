import AppKit
import SwiftUI

/// The brief pill that drops out of the notch when something is copied.
///
/// It exists to answer one question — "did it catch that?" — and then get out of
/// the way. So it never takes focus, never asks to be clicked, and holds just
/// long enough to be read out of the corner of an eye.
struct CaptureFlashView: View {
    @EnvironmentObject private var app: AppState
    @EnvironmentObject private var store: ClipStore

    /// The clip being shown. Kept after the coordinator clears its own, so the
    /// pill still has something to draw while it retracts.
    @State private var shown: Clip?
    /// Drives the small pop of the preview tile each time the pill has news.
    @State private var popped = false

    private var isVisible: Bool { app.capturedFlash != nil }

    /// The live clip if there is one, otherwise the one still retracting.
    /// Reading the coordinator first matters on the very first capture: the panel
    /// is built at that moment, so `onChange` never fires for that initial value
    /// and the pill would slide out empty.
    private var displayed: Clip? { app.capturedFlash ?? shown }

    var body: some View {
        pill
            .frame(width: Theme.flashSize.width, height: Theme.flashSize.height)
            .background(Color.black)
            .clipShape(BottomRoundedRectangle(radius: Theme.flashCornerRadius))
            .environment(\.colorScheme, .dark)
            .offset(y: isVisible ? 0 : -Theme.flashSize.height)
            .opacity(isVisible ? 1 : 0)
            .animation(
                isVisible
                    ? .spring(response: 0.34, dampingFraction: 0.72)
                    : .spring(response: 0.26, dampingFraction: 1.0),
                value: isVisible
            )
            .onChange(of: app.capturedFlash?.id) { _, id in
                if let clip = app.capturedFlash { shown = clip }
                guard id != nil else { popped = false; return }
                // Replayed on every new clip, so copying twice in a row reads as
                // two events rather than one pill that never moved.
                popped = false
                withAnimation(.spring(response: 0.3, dampingFraction: 0.55).delay(0.05)) {
                    popped = true
                }
            }
            // A click is a shortcut to the whole shelf, for when the glimpse
            // wasn't enough — but nothing depends on noticing that.
            .onTapGesture { app.showShelf() }
    }

    @ViewBuilder
    private var pill: some View {
        if let clip = displayed {
            HStack(spacing: 9) {
                preview(for: clip)
                    .frame(width: 26, height: 26)
                    .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                    .scaleEffect(popped ? 1 : 0.72)

                VStack(alignment: .leading, spacing: 1) {
                    Text(app.flashLabel)
                        .font(.system(size: 9, weight: .medium))
                        .foregroundStyle(.white.opacity(0.45))
                    Text(clip.title)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                }

                Spacer(minLength: 4)

                Image(systemName: clip.kind.symbol)
                    .font(.system(size: 11))
                    .foregroundStyle(.white.opacity(0.5))
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 6)
        }
    }

    @ViewBuilder
    private func preview(for clip: Clip) -> some View {
        switch clip.kind {
        case .image:
            if let image = store.image(for: clip) {
                Image(nsImage: image).resizable().aspectRatio(contentMode: .fill)
            } else {
                symbolTile(clip)
            }
        case .color:
            Color(nsColor: clip.color ?? .gray)
        case .file:
            Image(nsImage: NSWorkspace.shared.icon(forFile: clip.text.components(separatedBy: "\n")[0]))
                .resizable()
                .aspectRatio(contentMode: .fit)
        default:
            symbolTile(clip)
        }
    }

    private func symbolTile(_ clip: Clip) -> some View {
        ZStack {
            Color.white.opacity(0.10)
            Image(systemName: clip.kind.symbol)
                .font(.system(size: 11))
                .foregroundStyle(.white.opacity(0.7))
        }
    }
}
