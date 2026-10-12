import AppKit

final class HomeNoteWindowController: NSWindowController, NSWindowDelegate {
    private static let frameKey = "home-note-window-frame"
    private let defaults: UserDefaults

    init(window: NSWindow, defaults: UserDefaults) {
        self.defaults = defaults
        super.init(window: window)
        if let savedFrame = defaults.string(forKey: Self.frameKey) {
            window.setFrame(from: savedFrame)
        }
        window.delegate = self
    }

    required init?(coder: NSCoder) {
        fatalError("Home Note windows are created programmatically.")
    }

    func windowDidMove(_ notification: Notification) { saveFrame() }
    func windowDidResize(_ notification: Notification) { saveFrame() }
    func windowWillClose(_ notification: Notification) { saveFrame() }

    private func saveFrame() {
        guard let window else { return }
        defaults.set(window.frameDescriptor, forKey: Self.frameKey)
    }
}
