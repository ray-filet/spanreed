import AppKit

@MainActor
final class TextPresentation: NSObject {
    static let shared = TextPresentation()

    private let defaults = AppPaths.current.defaults
    private let savedSizeKey = "CurrentTextSize"
    private var currentSize: CGFloat = 20
    private var configuredDefaultSize: CGFloat = 20
    private var fontName = "SF Mono"
    private var hasLoadedConfiguration = false
    private var hasPersistedSize = false

    private override init() {
        super.init()
        let savedSize = defaults.double(forKey: savedSizeKey)
        if savedSize.isFinite, savedSize > 0 {
            currentSize = CGFloat(savedSize)
            hasPersistedSize = true
        }
    }

    var font: NSFont {
        if fontName != "SF Mono",
           let selectedFont = NSFontManager.shared.font(withFamily: fontName, traits: [], weight: 5, size: currentSize) {
            return selectedFont
        }
        return .monospacedSystemFont(ofSize: currentSize, weight: .regular)
    }

    /// Initial Config loading retains saved zoom. A changed default size on reload
    /// replaces that zoom, while changing only the Active Font retains it.
    func applyConfiguration(fontName: String, defaultSize: CGFloat) {
        guard defaultSize.isFinite, defaultSize > 0 else { return }
        let changedDefault = hasLoadedConfiguration && configuredDefaultSize != defaultSize
        if changedDefault || (!hasLoadedConfiguration && !hasPersistedSize) {
            currentSize = defaultSize
        }
        self.fontName = fontName
        configuredDefaultSize = defaultSize
        hasLoadedConfiguration = true
        if changedDefault { persistSize() }
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
        currentSize = size
        persistSize()
        updateOpenNotes()
    }

    private func persistSize() {
        defaults.set(Double(currentSize), forKey: savedSizeKey)
        hasPersistedSize = true
    }

    private func updateOpenNotes() {
        for case let note as NoteDocument in NSDocumentController.shared.documents {
            note.editor?.font = font
        }
    }
}
