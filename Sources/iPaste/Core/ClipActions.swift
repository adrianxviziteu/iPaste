import Foundation

/// Safe, local transformations offered for a clip.  They produce a preview
/// value first; the original history item is never changed until the person
/// explicitly saves the edit.
enum ClipAction: String, CaseIterable, Identifiable {
    case uppercase
    case lowercase
    case trimWhitespace
    case prettyJSON
    case compactJSON
    case cleanURL
    case markdownLink

    var id: String { rawValue }

    var label: String {
        switch self {
        case .uppercase: return "UPPERCASE"
        case .lowercase: return "lowercase"
        case .trimWhitespace: return "Trim whitespace"
        case .prettyJSON: return "Format JSON"
        case .compactJSON: return "Compact JSON"
        case .cleanURL: return "Clean tracking from URL"
        case .markdownLink: return "Make Markdown link"
        }
    }

    var symbol: String {
        switch self {
        case .uppercase, .lowercase: return "textformat"
        case .trimWhitespace: return "arrow.left.and.right.righttriangle.left.righttriangle.right"
        case .prettyJSON, .compactJSON: return "curlybraces"
        case .cleanURL: return "link.badge.plus"
        case .markdownLink: return "text.badge.plus"
        }
    }

    static func available(for clip: Clip) -> [ClipAction] {
        guard ![.image, .file, .multi].contains(clip.kind) else { return [] }
        var actions: [ClipAction] = [.uppercase, .lowercase, .trimWhitespace]
        if (try? JSONSerialization.jsonObject(with: Data(clip.text.utf8))) != nil {
            actions += [.prettyJSON, .compactJSON]
        }
        if URL(string: clip.text.trimmingCharacters(in: .whitespacesAndNewlines)) != nil {
            actions += [.cleanURL, .markdownLink]
        }
        return actions
    }

    func apply(to value: String) -> String? {
        switch self {
        case .uppercase: return value.uppercased()
        case .lowercase: return value.lowercased()
        case .trimWhitespace: return value.trimmingCharacters(in: .whitespacesAndNewlines)
        case .prettyJSON: return formatJSON(value, options: [.prettyPrinted, .sortedKeys])
        case .compactJSON: return formatJSON(value, options: [.sortedKeys])
        case .cleanURL:
            guard var components = URLComponents(string: value) else { return nil }
            let trackingNames: Set<String> = ["fbclid", "gclid", "mc_cid", "mc_eid", "ref", "ref_", "igshid"]
            components.queryItems = components.queryItems?.filter { item in
                let name = item.name.lowercased()
                return !name.hasPrefix("utm_") && !trackingNames.contains(name)
            }
            return components.url?.absoluteString
        case .markdownLink:
            guard let url = URL(string: value), let host = url.host else { return nil }
            return "[\(host)](\(url.absoluteString))"
        }
    }

    private func formatJSON(_ value: String, options: JSONSerialization.WritingOptions) -> String? {
        guard let data = value.data(using: .utf8),
              let object = try? JSONSerialization.jsonObject(with: data),
              let result = try? JSONSerialization.data(withJSONObject: object, options: options)
        else { return nil }
        return String(data: result, encoding: .utf8)
    }
}
