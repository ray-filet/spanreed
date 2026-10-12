import Foundation

public struct ConfigError: Equatable, Sendable {
    public let lineNumber: Int
    public let message: String
}

public struct ResolvedConfig: Equatable, Sendable {
    public var selectedFonts: [String] = ["SF Mono"]
    public var activeFont = "SF Mono"
    public var fontSize: Double = 20
    public var effectiveFont = "SF Mono"
    public var unavailableFonts: [String] = []
    public var errors: [ConfigError] = []
}

public enum Config {
    /// Rewrites the last valid Active Font value, retaining all surrounding bytes.
    /// If every Active Font value is invalid, repairs the last one; if absent, appends it.
    public static func rewriteActiveFont(_ text: String, fontName: String) -> String {
        var replacementRange: Range<String.Index>?
        var invalidValueRange: Range<String.Index>?
        for rawLine in text.split(omittingEmptySubsequences: false, whereSeparator: { $0.isNewline }) {
            let line = rawLine.startIndex == text.startIndex && rawLine.hasPrefix("\u{FEFF}")
                ? rawLine.dropFirst() : rawLine
            guard let separator = line.firstIndex(of: "="),
                  line[..<separator].trimmingCharacters(in: .whitespaces) == "active-font" else { continue }
            let value = line[line.index(after: separator)...]
            let trimmedValue = value.trimmingCharacters(in: .whitespaces)
            let start = value.rangeOfCharacter(from: .whitespaces.inverted)?.lowerBound ?? value.endIndex
            let end = value.rangeOfCharacter(from: .whitespaces.inverted, options: .backwards)?.upperBound ?? value.endIndex
            if !trimmedValue.isEmpty, !trimmedValue.contains("=") {
                replacementRange = start..<end
            } else {
                invalidValueRange = start..<end
            }
        }
        if let replacementRange = replacementRange ?? invalidValueRange {
            var rewritten = text
            rewritten.replaceSubrange(replacementRange, with: fontName)
            return rewritten
        }
        let newline = text.first(where: { $0.isNewline }).map(String.init) ?? "\n"
        let needsSeparator = !text.isEmpty && text != "\u{FEFF}" && text.last?.isNewline != true
        return text + (needsSeparator ? newline : "") + "active-font = \(fontName)" + newline
    }

    public static let defaultText = """
    # Font families shown in the font menus, separated by commas.
    selected-fonts = SF Mono

    # The Selected Font used in every note.
    active-font = SF Mono

    # Default text size in points. Command-0 returns to this size.
    font-size = 20

    """

    public static func parse(_ text: String, installedFontNames: Set<String>) -> ResolvedConfig {
        var config = ResolvedConfig()
        var selectedFontsLine = 1
        var activeFontLine: Int?
        let configText = text.hasPrefix("\u{FEFF}") ? String(text.dropFirst()) : text
        for (index, rawLine) in configText.split(omittingEmptySubsequences: false, whereSeparator: { $0.isNewline }).enumerated() {
            let line = rawLine.trimmingCharacters(in: .whitespaces)
            if line.isEmpty || line.hasPrefix("#") { continue }
            func report(_ message: String) {
                config.errors.append(ConfigError(lineNumber: index + 1, message: message))
            }
            guard let separator = line.firstIndex(of: "=") else {
                report("Expected key = value.")
                continue
            }
            let key = line[..<separator].trimmingCharacters(in: .whitespaces)
            let value = line[line.index(after: separator)...].trimmingCharacters(in: .whitespaces)
            switch key {
            case "selected-fonts":
                if value.isEmpty {
                    config.selectedFonts = ["SF Mono"]
                    selectedFontsLine = index + 1
                    continue
                }
                let fonts = value.split(separator: ",", omittingEmptySubsequences: false)
                    .map { $0.trimmingCharacters(in: .whitespaces) }
                guard !fonts.contains(where: { $0.isEmpty || $0.contains("=") }) else {
                    report("selected-fonts must be a comma-separated list of font names.")
                    continue
                }
                config.selectedFonts = fonts
                selectedFontsLine = index + 1
            case "active-font":
                guard !value.isEmpty, !value.contains("=") else {
                    report("active-font must be a font name.")
                    continue
                }
                config.activeFont = value
                activeFontLine = index + 1
            case "font-size":
                guard let size = Double(value), size.isFinite, size > 0 else {
                    report("font-size must be a positive, finite number.")
                    continue
                }
                config.fontSize = size
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
}
