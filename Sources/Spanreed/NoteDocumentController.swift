import AppKit

final class NoteDocumentController: NSDocumentController, NSMenuDelegate {
    let paths = AppPaths.current

    func menuNeedsUpdate(_ menu: NSMenu) {
        menu.removeAllItems()
        for url in recentDocumentURLs {
            let item = menu.addItem(withTitle: url.lastPathComponent,
                                    action: #selector(openRecentNote(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = url
            item.toolTip = url.path
        }
        if !menu.items.isEmpty { menu.addItem(.separator()) }
        let clear = menu.addItem(withTitle: "Clear Menu", action: #selector(clearRecentDocuments(_:)), keyEquivalent: "")
        clear.target = self
    }

    @objc private func openRecentNote(_ sender: NSMenuItem) {
        guard let url = sender.representedObject as? URL else { return }
        openDocument(withContentsOf: url, display: true) { _, _, error in
            if let error { NSApp.presentError(error) }
        }
    }

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
