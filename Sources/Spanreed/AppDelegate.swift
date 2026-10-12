import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    let noteController = NoteDocumentController()

    func applicationDidFinishLaunching(_ notification: Notification) {
        AppMenu.install()
        noteController.openHomeNote(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func applicationShouldOpenUntitledFile(_ sender: NSApplication) -> Bool { false }
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { false }
}
