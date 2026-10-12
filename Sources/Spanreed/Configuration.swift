import AppKit
import SpanreedCore

@MainActor
final class Configuration {
    static let shared = Configuration()

    private(set) var snapshot = Config.parse("", installedFontNames: ["SF Mono"])

    /// SF Mono first, then every other installed fixed-pitch family. AppKit does not list SF Mono as fixed-pitch.
    static let defaultFonts: [String] = {
        let names = NSFontManager.shared.availableFontNames(with: .fixedPitchFontMask) ?? []
        let families = Set(names.compactMap { NSFont(name: $0, size: 12)?.familyName })
        return ["SF Mono"] + families.subtracting(["SF Mono"]).sorted()
    }()

    private func complete(_ text: String, savedSize: Double) -> String {
        Config.addingMissingSettings(to: text, fallbackTextSize: savedSize, defaultFonts: Self.defaultFonts)
    }

    /// Reads UTF-8 strictly while retaining the BOM and line terminators for Config rewrites.
    func readText() throws -> String {
        let data = try Data(contentsOf: AppPaths.current.configURL)
        guard String(data: data, encoding: .utf8) != nil else {
            throw NSError(domain: NSCocoaErrorDomain, code: NSFileReadInapplicableStringEncodingError,
                          userInfo: [NSLocalizedDescriptionKey: "The Config is not valid UTF-8 text."])
        }
        return String(decoding: data, as: UTF8.self)
    }

    @discardableResult
    func reloadFromDisk() -> [String] {
        var text = ""
        var messages: [String] = []
        do {
            let paths = AppPaths.current
            let original = FileManager.default.fileExists(atPath: paths.configURL.path) ? try readText() : ""
            let savedSize = paths.defaults.double(forKey: "CurrentTextSize")
            text = complete(original, savedSize: savedSize)
            if !text.utf8.elementsEqual(original.utf8) {
                try FileManager.default.createDirectory(at: paths.configFolder, withIntermediateDirectories: true)
                try Data(text.utf8).write(to: paths.configURL, options: .atomic)
                if let note = NSDocumentController.shared.document(for: paths.configURL) as? NoteDocument {
                    note.fileModificationDate = try paths.configURL.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate
                    note.replaceConfigText(complete(note.text, savedSize: savedSize),
                                           savedText: text, actionName: "Persist Default Settings")
                }
            }
            paths.defaults.removeObject(forKey: "CurrentTextSize")
        } catch {
            messages.append(error.localizedDescription)
        }
        let installedFonts = Set(NSFontManager.shared.availableFontFamilies).union(["SF Mono"])
        snapshot = Config.parse(text, installedFontNames: installedFonts)
        messages += snapshot.errors.map { "Line \($0.lineNumber): \($0.message)" }
        applyAppearance()
        TextPresentation.shared.applyConfiguration(fontName: snapshot.effectiveFont,
                                                   defaultSize: CGFloat(snapshot.fontSize),
                                                   currentSize: CGFloat(snapshot.currentTextSize))
        return messages
    }

    func presentErrors(_ messages: [String]) {
        guard !messages.isEmpty else { return }
        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = "Config errors"
        alert.informativeText = messages.joined(separator: "\n")
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }

    func reloadAndPresentErrors() {
        presentErrors(reloadFromDisk())
    }

    func chooseFont(_ font: String) {
        guard snapshot.selectedFonts.contains(font), !snapshot.unavailableFonts.contains(font) else { return }
        rewriteConfig(actionName: "Change Active Font") { Config.rewriteActiveFont($0, fontName: font) }
    }

    func chooseAppearance(_ appearance: Appearance) {
        rewriteConfig(actionName: "Change Appearance") { Config.rewriteAppearance($0, appearance: appearance) }
    }

    func chooseTextSize(_ size: Double) {
        guard size.isFinite, size > 0 else { return }
        rewriteConfig(actionName: "Change Text Size") { Config.rewriteCurrentTextSize($0, size: size) }
    }

    private func applyAppearance() {
        switch snapshot.appearance {
        case .system: NSApp.appearance = nil
        case .light: NSApp.appearance = NSAppearance(named: .aqua)
        case .dark: NSApp.appearance = NSAppearance(named: .darkAqua)
        }
    }

    private func rewriteConfig(actionName: String, _ rewrite: (String) -> String) {
        do {
            let paths = AppPaths.current
            let savedSize = paths.defaults.double(forKey: "CurrentTextSize")
            let original = FileManager.default.fileExists(atPath: paths.configURL.path)
                ? try readText() : complete("", savedSize: savedSize)
            let savedText = complete(rewrite(original), savedSize: savedSize)
            try FileManager.default.createDirectory(at: paths.configFolder, withIntermediateDirectories: true)
            try Data(savedText.utf8).write(to: paths.configURL, options: .atomic)
            if let note = NSDocumentController.shared.document(for: paths.configURL) as? NoteDocument {
                // This app wrote the file. Keep classic Save from treating that as an external edit.
                note.fileModificationDate = try paths.configURL.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate
                note.replaceConfigText(complete(rewrite(note.text), savedSize: savedSize),
                                       savedText: savedText, actionName: actionName)
            }
            reloadAndPresentErrors()
        } catch {
            NSApp.presentError(error)
        }
    }
}
