import AppKit
import SwiftUI

struct TemporaryShareView: View {
    @EnvironmentObject private var app: AppState
    @ObservedObject var service: TemporaryShareService

    var body: some View {
        VStack(spacing: 14) {
            Text("Temporary local share")
                .font(.headline)
            Text("Scan on the same Wi-Fi. The link expires automatically and is never uploaded.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            if let image = service.qrCodeImage() {
                Image(nsImage: image)
                    .interpolation(.none)
                    .frame(width: 232, height: 232)
                    .padding(8)
                    .background(.white, in: RoundedRectangle(cornerRadius: 10))
            } else {
                ProgressView("Starting local link…").frame(height: 232)
            }
            if let url = service.url {
                Text(url.absoluteString)
                    .font(.system(size: 10, design: .monospaced))
                    .lineLimit(2)
                    .textSelection(.enabled)
                Button("Copy link") {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(url.absoluteString, forType: .string)
                }
            }
            if let expires = service.expiresAt {
                Text("Expires \(expires.formatted(date: .omitted, time: .shortened))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Button("Stop sharing") { app.stopSharing() }
        }
        .padding(20)
        .frame(width: 330)
    }
}
