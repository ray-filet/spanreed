import AppKit

@MainActor
final class TextPresentation: NSObject {
    static let shared = TextPresentation()

    private var currentSize: CGFloat = 20
    private var configuredDefaultSize: CGFloat = 20
    private var fontName = "SF Mono"

    var font: NSFont {
        if fontName != "SF Mono",
           let selectedFont = NSFontManager.shared.font(withFamily: fontName, traits: [], weight: 5, size: currentSize) {
            return selectedFont
        }
        return .monospacedSystemFont(ofSize: currentSize, weight: .regular)
    }

    func applyConfiguration(fontName: String, defaultSize: CGFloat, currentSize: CGFloat) {
        guard defaultSize.isFinite, defaultSize > 0, currentSize.isFinite, currentSize > 0 else { return }
        self.fontName = fontName
        self.currentSize = currentSize
        configuredDefaultSize = defaultSize
        updateOpenNotes()
    }

    @objc func increaseTextSize(_ sender: Any?) {
        setCurrentSize(currentSize + 1)
    }

    @objc func decreaseTextSize(_ sender: Any?) {
        setCurrentSize(min(currentSize, max(1, currentSize - 1)))
    }

    @objc func resetTextSize(_ sender: Any?) {
        setCurrentSize(configuredDefaultSize)
    }

    private func setCurrentSize(_ size: CGFloat) {
        guard size.isFinite, size > 0 else { return }
        Configuration.shared.chooseTextSize(Double(size))
    }

    private func updateOpenNotes() {
        for case let note as NoteDocument in NSDocumentController.shared.documents {
            note.editor?.font = font
        }
    }
}
