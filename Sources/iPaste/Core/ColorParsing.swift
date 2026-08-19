import AppKit

extension NSColor {
    /// A stable six-digit sRGB representation used by Color Picker clips.
    var ipasteHexString: String? {
        guard let color = usingColorSpace(.sRGB) else { return nil }
        let red = Int((color.redComponent * 255).rounded())
        let green = Int((color.greenComponent * 255).rounded())
        let blue = Int((color.blueComponent * 255).rounded())
        return String(format: "#%02X%02X%02X", red, green, blue)
    }

    /// Accepts #RGB, #RRGGBB, #RRGGBBAA, with or without the leading hash.
    convenience init?(hexString: String) {
        var hex = hexString.trimmingCharacters(in: .whitespacesAndNewlines)
        if hex.hasPrefix("#") { hex.removeFirst() }
        guard hex.allSatisfy({ $0.isHexDigit }) else { return nil }

        // #RGB expands to #RRGGBB.
        if hex.count == 3 {
            hex = hex.map { "\($0)\($0)" }.joined()
        }
        guard hex.count == 6 || hex.count == 8, let value = UInt64(hex, radix: 16) else { return nil }

        let hasAlpha = hex.count == 8
        let r = CGFloat((value >> (hasAlpha ? 24 : 16)) & 0xFF) / 255
        let g = CGFloat((value >> (hasAlpha ? 16 : 8)) & 0xFF) / 255
        let b = CGFloat((value >> (hasAlpha ? 8 : 0)) & 0xFF) / 255
        let a = hasAlpha ? CGFloat(value & 0xFF) / 255 : 1
        self.init(srgbRed: r, green: g, blue: b, alpha: a)
    }
}

enum ColorParsing {
    /// A string counts as a color only if it is *nothing but* a color —
    /// otherwise a sentence mentioning #fff would turn into a swatch.
    static func isPureColor(_ string: String) -> Bool {
        let s = string.trimmingCharacters(in: .whitespacesAndNewlines)
        guard s.count <= 32 else { return false }
        if NSColor(hexString: s) != nil, s.hasPrefix("#") || s.count == 6 || s.count == 8 {
            return true
        }
        return functionalColorRegex.firstMatch(
            in: s, range: NSRange(s.startIndex..., in: s)
        ) != nil
    }

    /// rgb(0 0 0), rgba(0,0,0,.5), hsl(210 40% 50%) and their variants.
    private static let functionalColorRegex = try! NSRegularExpression(
        pattern: #"^(rgba?|hsla?)\(\s*[\d.%\s,/]+\s*\)$"#,
        options: [.caseInsensitive]
    )
}
