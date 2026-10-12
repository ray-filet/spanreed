import AppKit

final class NoteWindowController: NSWindowController, NSWindowDelegate {
    private static let frameKey = "home-note-window-frame"
    private let defaults: UserDefaults

    init(window: NSWindow, defaults: UserDefaults, restoreHomeFrame: Bool) {
        self.defaults = defaults
        super.init(window: window)
        if restoreHomeFrame, let savedFrame = defaults.string(forKey: Self.frameKey) {
            window.setFrame(from: savedFrame)
        }
        window.delegate = self
    }

    required init?(coder: NSCoder) {
        fatalError("Note windows are created programmatically.")
    }

    override func synchronizeWindowTitleWithDocumentName() {
        super.synchronizeWindowTitleWithDocumentName()
        window?.standardWindowButton(.documentIconButton)?.isHidden = true
    }

    func windowDidMove(_ notification: Notification) { saveFrame() }
    func windowDidResize(_ notification: Notification) { saveFrame() }
    func windowWillClose(_ notification: Notification) { saveFrame() }

    private func saveFrame() {
        // Save As can turn an existing standard or Config window into the Home Note.
        guard (document as? NoteDocument)?.kind == .home, let window else { return }
        defaults.set(window.frameDescriptor, forKey: Self.frameKey)
    }
}
