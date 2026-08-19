import Foundation

/// Local, deterministic filters. Nothing is uploaded and every classification
/// can be explained by the content that matched it.
enum SmartFilter: String, CaseIterable, Identifiable {
    case email
    case phone
    case json
    case command
    case token
    case address

    var id: String { rawValue }

    var label: String {
        switch self {
        case .email:   return "Email"
        case .phone:   return "Phone"
        case .json:    return "JSON"
        case .command: return "Commands"
        case .token:   return "Tokens"
        case .address: return "Addresses"
        }
    }

    var symbol: String {
        switch self {
        case .email:   return "at"
        case .phone:   return "phone"
        case .json:    return "curlybraces"
        case .command: return "terminal"
        case .token:   return "key"
        case .address: return "mappin.and.ellipse"
        }
    }
}

enum SmartClipClassifier {
    static func filters(for clip: Clip) -> Set<SmartFilter> {
        let text = [clip.text, clip.ocrText ?? ""].joined(separator: "\n")
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }

        var result = Set<SmartFilter>()
        if matches(#"\b[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}\b"#, in: trimmed, options: [.caseInsensitive]) {
            result.insert(.email)
        }
        if matches(#"(?<!\d)(?:\+?\d[\d .()\-]{7,}\d)(?!\d)"#, in: trimmed) {
            result.insert(.phone)
        }
        if looksLikeJSON(trimmed) { result.insert(.json) }
        if looksLikeCommand(trimmed) { result.insert(.command) }
        if SensitiveContentDetector.containsToken(trimmed) { result.insert(.token) }
        if matches(#"\b(?:street|st\.?|road|rd\.?|avenue|ave\.?|boulevard|blvd\.?|strada|str\.?|calea|bulevardul)\s+[\p{L}0-9 .'-]+\s+\d+[A-Z]?\b"#, in: trimmed, options: [.caseInsensitive]) {
            result.insert(.address)
        }
        return result
    }

    static func matches(_ filter: SmartFilter, clip: Clip) -> Bool {
        filters(for: clip).contains(filter)
    }

    private static func looksLikeJSON(_ text: String) -> Bool {
        guard let first = text.first, let last = text.last,
              (first == "{" && last == "}") || (first == "[" && last == "]"),
              let data = text.data(using: .utf8)
        else { return false }
        return (try? JSONSerialization.jsonObject(with: data)) != nil
    }

    private static func looksLikeCommand(_ text: String) -> Bool {
        let firstLine = text.split(separator: "\n", maxSplits: 1).first.map(String.init) ?? text
        return matches(#"^\s*(?:sudo\s+)?(?:git|npm|pnpm|yarn|swift|xcodebuild|docker|kubectl|curl|ssh|cd|ls|mkdir|brew|python3?|node|rg)\b"#, in: firstLine, options: [.caseInsensitive])
    }

    private static func matches(
        _ pattern: String,
        in text: String,
        options: NSRegularExpression.Options = []
    ) -> Bool {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: options) else { return false }
        return regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)) != nil
    }
}

enum SensitiveContentDetector {
    static func isSensitive(_ text: String) -> Bool {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }

        if containsToken(trimmed) { return true }
        if matches(#"-----BEGIN (?:RSA |EC |OPENSSH )?PRIVATE KEY-----"#, in: trimmed) { return true }
        if matches(#"(?i)\b(?:password|passwd|passphrase|secret|api[_ -]?key|access[_ -]?token)\s*[:=]\s*[^\s]{6,}"#, in: trimmed) { return true }
        if containsValidCardNumber(trimmed) { return true }
        return false
    }

    static func containsToken(_ text: String) -> Bool {
        let patterns = [
            #"\beyJ[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{8,}\b"#,
            #"\b(?:sk|pk)-(?:live|test)-[A-Za-z0-9_-]{12,}\b"#,
            #"\bgh[opusr]_[A-Za-z0-9]{20,}\b"#,
            #"\bxox[baprs]-[A-Za-z0-9-]{10,}\b"#,
            #"\bAKIA[A-Z0-9]{16}\b"#
        ]
        return patterns.contains { matches($0, in: text, options: [.caseInsensitive]) }
    }

    private static func containsValidCardNumber(_ text: String) -> Bool {
        guard let regex = try? NSRegularExpression(pattern: #"(?<!\d)(?:\d[ -]?){13,19}(?!\d)"#) else { return false }
        let range = NSRange(text.startIndex..., in: text)
        return regex.matches(in: text, range: range).contains { match in
            guard let swiftRange = Range(match.range, in: text) else { return false }
            let digits = text[swiftRange].compactMap(\.wholeNumberValue)
            return (13...19).contains(digits.count) && luhnValid(digits)
        }
    }

    private static func luhnValid(_ digits: [Int]) -> Bool {
        let sum = digits.reversed().enumerated().reduce(0) { total, item in
            let (offset, digit) = item
            guard offset % 2 == 1 else { return total + digit }
            let doubled = digit * 2
            return total + (doubled > 9 ? doubled - 9 : doubled)
        }
        return sum > 0 && sum % 10 == 0
    }

    private static func matches(
        _ pattern: String,
        in text: String,
        options: NSRegularExpression.Options = []
    ) -> Bool {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: options) else { return false }
        return regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)) != nil
    }
}
