import Combine
import CoreImage
import CoreImage.CIFilterBuiltins
import Foundation
import Network
import AppKit

/// A tiny, local-only HTTP endpoint for a single clip. It has no account, no
/// relay server and no persistence: the link stops working after expiry or when
/// iPaste quits. A random capability token prevents casual discovery on a LAN.
@MainActor
final class TemporaryShareService: ObservableObject {
    @Published private(set) var url: URL?
    @Published private(set) var expiresAt: Date?

    private var listener: NWListener?
    private var token = ""
    private var payload = Data()
    private var contentType = "text/plain; charset=utf-8"
    private var expiryTask: Task<Void, Never>?

    deinit { listener?.cancel() }

    func share(text: String, for duration: TimeInterval = 15 * 60) {
        share(data: Data(text.utf8), contentType: "text/plain; charset=utf-8", for: duration)
    }

    func share(data: Data, contentType: String, for duration: TimeInterval = 15 * 60) {
        stop()
        payload = data
        self.contentType = contentType
        token = UUID().uuidString.replacingOccurrences(of: "-", with: "")
        let listener: NWListener
        do {
            listener = try NWListener(using: .tcp, on: .any)
        } catch {
            NSLog("iPaste: could not start temporary sharing — \(error.localizedDescription)")
            return
        }
        self.listener = listener
        listener.newConnectionHandler = { [weak self] connection in
            connection.start(queue: .global(qos: .utility))
            connection.receive(minimumIncompleteLength: 1, maximumLength: 8_192) { data, _, _, _ in
                guard let self else { connection.cancel(); return }
                let request = data.flatMap { String(data: $0, encoding: .utf8) } ?? ""
                Task { @MainActor in self.respond(to: connection, request: request) }
            }
        }
        listener.stateUpdateHandler = { [weak self] state in
            guard case .ready = state, let port = listener.port else { return }
            Task { @MainActor in self?.publishURL(port: port, duration: duration) }
        }
        listener.start(queue: .global(qos: .utility))
    }

    func stop() {
        expiryTask?.cancel()
        expiryTask = nil
        listener?.cancel()
        listener = nil
        url = nil
        expiresAt = nil
        payload = Data()
        contentType = "text/plain; charset=utf-8"
    }

    func qrCodeImage() -> NSImage? {
        guard let url else { return nil }
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(url.absoluteString.utf8)
        filter.correctionLevel = "M"
        guard let output = filter.outputImage?.transformed(by: CGAffineTransform(scaleX: 8, y: 8)) else { return nil }
        let representation = NSCIImageRep(ciImage: output)
        let image = NSImage(size: representation.size)
        image.addRepresentation(representation)
        image.size = NSSize(width: 232, height: 232)
        return image
    }

    private func publishURL(port: NWEndpoint.Port, duration: TimeInterval) {
        guard url == nil else { return }
        let rawHost = Host.current().name ?? ProcessInfo.processInfo.hostName
        let host = rawHost.replacingOccurrences(of: ".local", with: "")
            .replacingOccurrences(of: " ", with: "-") + ".local"
        url = URL(string: "http://\(host):\(port.rawValue)/\(token)")
        expiresAt = Date().addingTimeInterval(duration)
        expiryTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(duration))
            guard !Task.isCancelled else { return }
            self?.stop()
        }
    }

    private func respond(to connection: NWConnection, request: String) {
        let valid = url != nil && request.hasPrefix("GET /\(token) ")
        let status = valid ? "200 OK" : "404 Not Found"
        let body = valid ? payload : Data("This temporary iPaste link has expired.".utf8)
        let type = valid ? contentType : "text/plain; charset=utf-8"
        let header = "HTTP/1.1 \(status)\r\nContent-Type: \(type)\r\nContent-Length: \(body.count)\r\nCache-Control: no-store\r\nConnection: close\r\n\r\n"
        connection.send(content: Data(header.utf8) + body, completion: .contentProcessed { _ in connection.cancel() })
    }
}
