import AppKit

final class NoteDocumentController: NSDocumentController {
    let paths = AppPaths.current

    @objc func openHomeNote(_ sender: Any?) {
        if let note = documents.first(where: { $0.fileURL?.standardizedFileURL == paths.homeNoteURL.standardizedFileURL }) {
            note.showWindows()
            return
        }
        do {
            try FileManager.default.createDirectory(at: paths.homeNoteFolder, withIntermediateDirectories: true)
            if !FileManager.default.fileExists(atPath: paths.homeNoteURL.path) {
                try Data().write(to: paths.homeNoteURL, options: .atomic)
            }
            let note = try NoteDocument(contentsOf: paths.homeNoteURL, ofType: "public.text")
            note.kind = .home
            addDocument(note)
            note.makeWindowControllers()
            note.showWindows()
        } catch {
            NSApp.presentError(error)
        }
    }
}
