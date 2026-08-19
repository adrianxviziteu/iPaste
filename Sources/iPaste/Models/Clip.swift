import AppKit
import Foundation

/// What kind of thing was copied. Detected automatically at capture time.
enum ClipKind: String, Codable, CaseIterable, Sendable {
    case text
    case link
    case code
    case color
    case image
    case file
    case multi

    var label: String {
        switch self {
        case .text:  return "Text"
        case .link:  return "Links"
        case .code:  return "Code"
        case .color: return "Colors"
        case .image: return "Images"
        case .file:  return "Files"
        case .multi: return "Multi-clip"
        }
    }

    var symbol: String {
        switch self {
        case .text:  return "text.alignleft"
        case .link:  return "link"
        case .code:  return "chevron.left.forwardslash.chevron.right"
        case .color: return "paintpalette"
        case .image: return "photo"
        case .file:  return "doc"
        case .multi: return "square.stack.3d.up"
        }
    }
}

/// How a reminder knows when to surface. The associated app details are kept
/// on `ClipReminder` so the persisted value stays simple and forwards-compatible.
enum ClipReminderKind: String, Codable, Hashable, Sendable {
    case atDate
    case sourceAppReturn
}

/// A single reminder attached to a clip. One reminder per clip keeps the
/// history easy to scan and makes changing a reminder predictable.
struct ClipReminder: Codable, Hashable, Sendable {
    var kind: ClipReminderKind
    var fireDate: Date?
    var sourceBundleID: String?
    var sourceAppName: String?
    var createdAt: Date

    static func at(_ date: Date, createdAt: Date = Date()) -> ClipReminder {
        ClipReminder(kind: .atDate, fireDate: date, createdAt: createdAt)
    }

    static func whenReturningToSourceApp(
        bundleID: String,
        appName: String?,
        createdAt: Date = Date()
    ) -> ClipReminder {
        ClipReminder(
            kind: .sourceAppReturn,
            sourceBundleID: bundleID,
            sourceAppName: appName,
            createdAt: createdAt
        )
    }

    private init(
        kind: ClipReminderKind,
        fireDate: Date? = nil,
        sourceBundleID: String? = nil,
        sourceAppName: String? = nil,
        createdAt: Date
    ) {
        self.kind = kind
        self.fireDate = fireDate
        self.sourceBundleID = sourceBundleID
        self.sourceAppName = sourceAppName
        self.createdAt = createdAt
    }

    var label: String {
        switch kind {
        case .atDate:
            guard let fireDate else { return "Reminder" }
            return fireDate.formatted(date: .abbreviated, time: .shortened)
        case .sourceAppReturn:
            return "When you return to \(sourceAppName ?? "the source app")"
        }
    }
}

/// One entry in the history. Codable so it persists as JSON; images live on
/// disk separately and only their filename is kept here.
struct Clip: Identifiable, Codable, Hashable, Sendable {
    let id: UUID
    var kind: ClipKind
    /// The textual content: the text itself, the URL, the color hex, or the file path.
    var text: String
    /// Name of the PNG in Application Support/iPaste/Images, for `.image` clips.
    var imageFilename: String?
    /// Text pulled out of an image by OCR (v2). Included in search.
    var ocrText: String?
    var sourceAppName: String?
    var sourceBundleID: String?
    var createdAt: Date
    var pinned: Bool
    /// A collection the user made (v2). nil means it lives only in the history.
    var category: String?
    /// A shorthand like `;welcome` that inserts this clip (v2).
    var shortcut: String?
    /// An optional reminder, shared by every kind of saved clip.
    var reminder: ClipReminder?
    /// Fingerprint for deduplication — identical content is never stored twice.
    var fingerprint: String
    var byteSize: Int

    init(
        id: UUID = UUID(),
        kind: ClipKind,
        text: String,
        imageFilename: String? = nil,
        ocrText: String? = nil,
        sourceAppName: String? = nil,
        sourceBundleID: String? = nil,
        createdAt: Date = Date(),
        pinned: Bool = false,
        category: String? = nil,
        shortcut: String? = nil,
        reminder: ClipReminder? = nil,
        fingerprint: String,
        byteSize: Int
    ) {
        self.id = id
        self.kind = kind
        self.text = text
        self.imageFilename = imageFilename
        self.ocrText = ocrText
        self.sourceAppName = sourceAppName
        self.sourceBundleID = sourceBundleID
        self.createdAt = createdAt
        self.pinned = pinned
        self.category = category
        self.shortcut = shortcut
        self.reminder = reminder
        self.fingerprint = fingerprint
        self.byteSize = byteSize
    }

    /// The title shown in a list — a single line, stripped of surrounding space.
    var title: String {
        switch kind {
        case .image:
            return ocrText?.firstMeaningfulLine ?? "Image"
        case .file:
            return (text as NSString).lastPathComponent
        default:
            return text.firstMeaningfulLine ?? "Empty"
        }
    }

    /// The second line of a card: context, not content.
    var subtitle: String {
        var parts: [String] = [kind.label]
        if let app = sourceAppName { parts.append(app) }
        parts.append(createdAt.relativeShort)
        if reminder != nil { parts.append("reminder") }
        return parts.joined(separator: " · ")
    }

    /// Everything search looks through: content, OCR text, source app, collection.
    var searchHaystack: String {
        [text, ocrText ?? "", sourceAppName ?? "", category ?? "", shortcut ?? ""]
            .joined(separator: " ")
            .lowercased()
    }

    /// The color itself, for `.color` clips.
    var color: NSColor? {
        guard kind == .color else { return nil }
        return NSColor(hexString: text)
    }
}

extension String {
    var firstMeaningfulLine: String? {
        for line in split(separator: "\n", omittingEmptySubsequences: false) {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if !trimmed.isEmpty { return trimmed }
        }
        return nil
    }
}

extension Date {
    /// "now", "5m", "3h", "2d" — short, so it never breaks a card's layout.
    var relativeShort: String {
        let seconds = Int(Date().timeIntervalSince(self))
        switch seconds {
        case ..<60:     return "now"
        case ..<3600:   return "\(seconds / 60)m"
        case ..<86_400: return "\(seconds / 3600)h"
        default:        return "\(seconds / 86_400)d"
        }
    }
}
