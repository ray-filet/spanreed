import Foundation

public struct ConfigError: Equatable, Sendable {
    public let lineNumber: Int
    public let message: String
}

public enum Appearance: String, CaseIterable, Sendable {
    case system, light, dark
}

public struct ResolvedConfig: Equatable, Sendable {
    public var selectedFonts: [String] = ["SF Mono"]
    public var activeFont = "SF Mono"
    public var fontSize: Double = 20
    public var appearance = Appearance.system
    public var effectiveFont = "SF Mono"
    public var unavailableFonts: [String] = []
    public var errors: [ConfigError] = []
}

public enum Config {
    /// Rewrites the last valid Active Font value, retaining all surrounding bytes.
    /// If every Active Font value is invalid, repairs the last one; if absent, appends it.
    public static func rewriteActiveFont(_ text: String, fontName: String) -> String {
        rewriteValue(of: "active-font", in: text, to: fontName, isValid: isValidActiveFont)
    }

    /// Rewrites the last valid appearance value with the same byte-preserving rules as the Active Font.
    public static func rewriteAppearance(_ text: String, appearance: Appearance) -> String {
        rewriteValue(of: "appearance", in: text, to: appearance.rawValue) { Appearance(rawValue: String($0)) != nil }
    }

    private static func rewriteValue(of key: String, in text: String, to newValue: String,
                                     isValid: (Substring) -> Bool) -> String {
        var replacementRange: Range<String.Index>?
        var invalidValueRange: Range<String.Index>?
        for line in scanLines(text) where line.key == key {
            let range = line.value.startIndex..<line.value.endIndex
            if isValid(line.value) {
                replacementRange = range
            } else {
                invalidValueRange = range
            }
        }
        if let replacementRange = replacementRange ?? invalidValueRange {
            var rewritten = text
            rewritten.replaceSubrange(replacementRange, with: newValue)
            return rewritten
        }
        let newline = text.first(where: { $0.isNewline }).map(String.init) ?? "\n"
        let needsSeparator = !text.isEmpty && text != "\u{FEFF}" && text.last?.isNewline != true
        return text + (needsSeparator ? newline : "") + "\(key) = \(newValue)" + newline
    }

    public static let defaultText = """
    # Font families shown in the font menus, separated by commas.
    selected-fonts = SF Mono

    # The Selected Font used in every note.
    active-font = SF Mono

    # Default text size in points. Command-0 returns to this size.
    font-size = 20

    # Light or dark look: system (follow macOS), light, or dark.
    appearance = system

    """

    public static func parse(_ text: String, installedFontNames: Set<String>) -> ResolvedConfig {
        var config = ResolvedConfig()
        var selectedFontsLine = 1
        var activeFontLine: Int?
        for line in scanLines(text) {
            func report(_ message: String) {
                config.errors.append(ConfigError(lineNumber: line.number, message: message))
            }
            guard let key = line.key else {
                report("Expected key = value.")
                continue
            }
            let value = line.value
            switch key {
            case "selected-fonts":
                if value.isEmpty {
                    config.selectedFonts = ["SF Mono"]
                    selectedFontsLine = line.number
                    continue
                }
                let fonts = value.split(separator: ",", omittingEmptySubsequences: false)
                    .map { $0.trimmingCharacters(in: .whitespaces) }
                guard !fonts.contains(where: { $0.isEmpty || $0.contains("=") }) else {
                    report("selected-fonts must be a comma-separated list of font names.")
                    continue
                }
                config.selectedFonts = fonts
                selectedFontsLine = line.number
            case "active-font":
                guard isValidActiveFont(value) else {
                    report("active-font must be a font name.")
                    continue
                }
                config.activeFont = String(value)
                activeFontLine = line.number
            case "font-size":
                guard let size = Double(value), size.isFinite, size > 0 else {
                    report("font-size must be a positive, finite number.")
                    continue
                }
                config.fontSize = size
            case "appearance":
                guard let appearance = Appearance(rawValue: String(value)) else {
                    report("appearance must be system, light, or dark.")
                    continue
                }
                config.appearance = appearance
            default:
                report("Unknown key '\(key)'.")
            }
        }
        config.effectiveFont = config.activeFont
        if !config.selectedFonts.contains(config.activeFont) {
            config.errors.append(ConfigError(lineNumber: activeFontLine ?? selectedFontsLine,
                                             message: "active-font '\(config.activeFont)' is not in selected-fonts. Using SF Mono."))
            config.effectiveFont = "SF Mono"
        }
        for font in config.selectedFonts where !installedFontNames.contains(font) {
            config.unavailableFonts.append(font)
            config.errors.append(ConfigError(lineNumber: selectedFontsLine,
                                             message: "Selected Font '\(font)' is not installed."))
            if font == config.activeFont { config.effectiveFont = "SF Mono" }
        }
        config.errors.sort { $0.lineNumber < $1.lineNumber }
        return config
    }

    private struct ScannedLine {
        let number: Int
        let key: String?
        // The slice retains indices into the original text for byte-preserving rewrites.
        let value: Substring
    }

    private static func scanLines(_ text: String) -> [ScannedLine] {
        text.split(omittingEmptySubsequences: false, whereSeparator: { $0.isNewline })
            .enumerated().compactMap { index, rawLine in
                let line = index == 0 && rawLine.hasPrefix("\u{FEFF}") ? rawLine.dropFirst() : rawLine
                let content = line.trimmingCharacters(in: .whitespaces)
                guard !content.isEmpty, !content.hasPrefix("#") else { return nil }
                guard let separator = line.firstIndex(of: "=") else {
                    return ScannedLine(number: index + 1, key: nil, value: line[line.endIndex...])
                }
                let key = line[..<separator].trimmingCharacters(in: .whitespaces)
                let value = line[line.index(after: separator)...]
                let start = value.rangeOfCharacter(from: .whitespaces.inverted)?.lowerBound ?? value.endIndex
                let end = value.rangeOfCharacter(from: .whitespaces.inverted, options: .backwards)?.upperBound ?? value.endIndex
                return ScannedLine(number: index + 1, key: key, value: value[start..<end])
            }
    }

    private static func isValidActiveFont(_ value: Substring) -> Bool {
        !value.isEmpty && !value.contains("=")
    }
}
