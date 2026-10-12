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
