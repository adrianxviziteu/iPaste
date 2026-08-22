import Foundation

/// Explainable local query expansion. This is intentionally not a remote AI
/// service: it ranks clips by words and a small bilingual synonym map while
/// retaining the exact-match behavior people expect from search.
enum LocalSemanticSearch {
    private static let relatedTerms: [String: Set<String>] = [
        "email": ["mail", "e-mail", "gmail", "outlook", "inbox"],
        "mail": ["email", "e-mail", "gmail", "outlook"],
        "factura": ["invoice", "billing", "payment", "plată"],
        "invoice": ["factura", "billing", "payment"],
        "client": ["customer", "customer", "contact", "clientul"],
        "adresă": ["address", "location", "strada"],
        "address": ["adresă", "location", "street"],
        "parolă": ["password", "secret"],
        "password": ["parolă", "secret"],
        "cod": ["code", "snippet", "json", "command"],
        "code": ["cod", "snippet", "json", "command"]
    ]

    static func ranked(_ clips: [Clip], query: String) -> [Clip] {
        let terms = query.lowercased().split(whereSeparator: { $0.isWhitespace || $0.isPunctuation })
            .map(String.init)
        guard !terms.isEmpty else { return clips }

        let matches: [(clip: Clip, score: Int)] = clips.compactMap { clip in
            let value = score(for: clip, terms: terms)
            return value > 0 ? (clip: clip, score: value) : nil
        }
        return matches
        .sorted { lhs, rhs in
            lhs.score == rhs.score ? lhs.clip.createdAt > rhs.clip.createdAt : lhs.score > rhs.score
        }
        .map(\.clip)
    }

    private static func score(for clip: Clip, terms: [String]) -> Int {
        let haystack: String = clip.searchHaystack
        var result = 0
        for term in terms {
            if haystack.range(of: term) != nil { result += 12 }
            guard let expansions = relatedTerms[term] else { continue }
            for expansion in expansions {
                if haystack.range(of: expansion) != nil { result += 5 }
            }
        }
        return result + min(clip.useCount, 8)
    }
}
