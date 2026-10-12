import AppKit
import SpanreedCore

@MainActor
final class Configuration {
    static let shared = Configuration()

    private(set) var snapshot = Config.parse("", installedFontNames: ["SF Mono"])

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
        if FileManager.default.fileExists(atPath: AppPaths.current.configURL.path) {
            do {
                text = try readText()
            } catch {
                messages.append(error.localizedDescription)
            }
        }
        let installedFonts = Set(NSFontManager.shared.availableFontFamilies).union(["SF Mono"])
        snapshot = Config.parse(text, installedFontNames: installedFonts)
        messages += snapshot.errors.map { "Line \($0.lineNumber): \($0.message)" }
        TextPresentation.shared.applyConfiguration(fontName: snapshot.effectiveFont,
                                                   defaultSize: CGFloat(snapshot.fontSize))
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
        do {
            let paths = AppPaths.current
            let original = FileManager.default.fileExists(atPath: paths.configURL.path)
                ? try readText() : Config.defaultText
            let savedText = Config.rewriteActiveFont(original, fontName: font)
            try FileManager.default.createDirectory(at: paths.configFolder, withIntermediateDirectories: true)
            try Data(savedText.utf8).write(to: paths.configURL, options: .atomic)
            if let note = NSDocumentController.shared.document(for: paths.configURL) as? NoteDocument {
                // This app wrote the file. Keep classic Save from treating that as an external edit.
                note.fileModificationDate = try paths.configURL.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate
                let updatedText = Config.rewriteActiveFont(note.text, fontName: font)
                note.replaceConfigText(updatedText, savedText: savedText)
            }
            reloadAndPresentErrors()
        } catch {
            NSApp.presentError(error)
        }
    }
}
