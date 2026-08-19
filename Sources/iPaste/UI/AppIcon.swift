import AppKit
import SwiftUI

/// The icon of the app a clip came from, looked up by bundle ID.
/// Results are cached: `icon(forFile:)` hits the disk on every call.
enum AppIconProvider {
    private static var cache: [String: NSImage] = [:]

    static func icon(forBundleID bundleID: String?) -> NSImage? {
        guard let bundleID else { return nil }
        if let cached = cache[bundleID] { return cached }
        guard let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) else {
            return nil
        }
        let icon = NSWorkspace.shared.icon(forFile: url.path)
        cache[bundleID] = icon
        return icon
    }
}

extension Int {
    /// "3.5 MB" — the system format, using the user's own regional separators.
    var formattedByteSize: String {
        ByteCountFormatter.string(fromByteCount: Int64(self), countStyle: .file)
    }
}
