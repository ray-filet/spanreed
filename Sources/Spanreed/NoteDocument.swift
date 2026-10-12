import AppKit

class NoteDocument: NSDocument, NSTextViewDelegate {
    enum Kind { case home, standard, config }

    var kind: Kind = .standard
    private(set) var text = ""
    private(set) var editor: NSTextView?
    private var savedConfigText = ""

    override var displayName: String! {
        get {
            switch kind {
            case .home: return "Home Note"
            case .config: return "Config"
            case .standard: return super.displayName
            }
        }
        set { super.displayName = newValue }
    }

    override var isDocumentEdited: Bool {
        switch kind {
        case .home: return false
        case .config: return !text.utf8.elementsEqual(savedConfigText.utf8)
        case .standard: return super.isDocumentEdited
        }
    }

    override class var autosavesInPlace: Bool { false }
    override class var autosavesDrafts: Bool { false }
    override class var preservesVersions: Bool { false }

    override func saveAs(_ sender: Any?) {
        if kind == .home {
            runModalSavePanel(for: .saveToOperation, delegate: nil, didSave: nil, contextInfo: nil)
        } else {
            super.saveAs(sender)
        }
    }

    override func makeWindowControllers() {
        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 720, height: 540),
                              styleMask: [.titled, .closable, .miniaturizable, .resizable],
                              backing: .buffered, defer: false)
        window.minSize = NSSize(width: 360, height: 240)
        window.isRestorable = false
        window.center()
        let scrollView = NSScrollView(frame: window.contentView!.bounds)
        scrollView.autoresizingMask = [.width, .height]
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        let textView = NSTextView(frame: scrollView.contentView.bounds)
        textView.autoresizingMask = [.width]
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.minSize = NSSize(width: 0, height: scrollView.contentSize.height)
        textView.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        textView.textContainer?.containerSize = NSSize(width: scrollView.contentSize.width, height: CGFloat.greatestFiniteMagnitude)
        textView.textContainer?.widthTracksTextView = true
        textView.textContainerInset = NSSize(width: 12, height: 12)
        textView.isRichText = false
        textView.importsGraphics = false
        textView.allowsUndo = true
        textView.usesFindBar = true
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.isAutomaticTextReplacementEnabled = false
        textView.isAutomaticSpellingCorrectionEnabled = false
        textView.isAutomaticLinkDetectionEnabled = false
        textView.isAutomaticDataDetectionEnabled = false
        textView.isAutomaticTextCompletionEnabled = false
        textView.font = TextPresentation.shared.font
        textView.string = text
        textView.delegate = self
        textView.setAccessibilityIdentifier("note-editor")
        scrollView.documentView = textView
        window.contentView?.addSubview(scrollView)
        editor = textView
        if kind == .home {
            addWindowController(HomeNoteWindowController(window: window, defaults: AppPaths.current.defaults))
        } else {
            addWindowController(NSWindowController(window: window))
        }
        if kind == .home { window.title = "Home Note" }
        window.makeFirstResponder(textView)
    }

    override func read(from url: URL, ofType typeName: String) throws {
        if url.standardizedFileURL == AppPaths.current.homeNoteURL.standardizedFileURL {
            kind = .home
        } else if url.standardizedFileURL == AppPaths.current.configURL.standardizedFileURL {
            kind = .config
        } else {
            kind = .standard
        }
        try super.read(from: url, ofType: typeName)
    }

    override func read(from data: Data, ofType typeName: String) throws {
        guard let decoded = String(data: data, encoding: .utf8) else {
            throw NSError(domain: NSCocoaErrorDomain, code: NSFileReadInapplicableStringEncodingError,
                          userInfo: [NSLocalizedDescriptionKey: "This note is not valid UTF-8 text."])
        }
        // Validate strictly, but retain the Config BOM and line endings for font rewrites.
        text = kind == .config ? String(decoding: data, as: UTF8.self) : decoded
        if kind == .config { savedConfigText = text }
        editor?.string = text
    }

    override func save(to url: URL, ofType typeName: String, for saveOperation: NSDocument.SaveOperationType,
                       completionHandler: @escaping (Error?) -> Void) {
        super.save(to: url, ofType: typeName, for: saveOperation) { error in
            if error == nil, saveOperation != .saveToOperation {
                if url.standardizedFileURL == AppPaths.current.configURL.standardizedFileURL {
                    self.kind = .config
                    self.savedConfigText = (try? Configuration.shared.readText()) ?? self.text
                    self.synchronizeConfigChangeCount()
                } else if url.standardizedFileURL == AppPaths.current.homeNoteURL.standardizedFileURL {
                    self.kind = .home
                } else {
                    self.kind = .standard
                }
            }
            completionHandler(error)
            if error == nil, url.standardizedFileURL == AppPaths.current.configURL.standardizedFileURL {
                Configuration.shared.reloadAndPresentErrors()
            }
        }
    }

    override func data(ofType typeName: String) throws -> Data {
        Data(text.utf8)
    }

    /// A font-menu rewrite updates this note independently of the disk Config,
    /// so other unsaved edits stay here until the user saves them.
    func replaceConfigText(_ updatedText: String, savedText: String) {
        guard kind == .config else { return }
        savedConfigText = savedText
        if let editor, !text.utf8.elementsEqual(updatedText.utf8) {
            let selection = editor.selectedRange()
            let original = text as NSString
            let updated = updatedText as NSString
            let sharedLength = min(original.length, updated.length)
            var prefix = 0
            while prefix < sharedLength, original.character(at: prefix) == updated.character(at: prefix) { prefix += 1 }
            // A replacement must not divide a Unicode scalar's UTF-16 surrogate pair.
            if prefix > 0, prefix < sharedLength,
               (0xDC00...0xDFFF).contains(original.character(at: prefix)) || (0xDC00...0xDFFF).contains(updated.character(at: prefix)) {
                prefix -= 1
            }
            var suffix = 0
            while suffix < sharedLength - prefix,
                  original.character(at: original.length - suffix - 1) == updated.character(at: updated.length - suffix - 1) {
                suffix += 1
            }
            if suffix > 0, (0xDC00...0xDFFF).contains(original.character(at: original.length - suffix)) { suffix -= 1 }
            let range = NSRange(location: prefix, length: original.length - prefix - suffix)
            let replacementRange = NSRange(location: prefix, length: updated.length - prefix - suffix)
            let replacement = NSAttributedString(string: updated.substring(with: replacementRange))
            // A validated edit registers its own undo before earlier edits can be undone.
            editor.breakUndoCoalescing()
            guard editor.performValidatedReplacement(in: range, with: replacement) else { return }
            editor.breakUndoCoalescing()
            editor.undoManager?.setActionName("Change Active Font")
            let delta = replacementRange.length - range.length
            func adjusted(_ position: Int) -> Int {
                if position <= range.location { return position }
                if position >= NSMaxRange(range) { return position + delta }
                return range.location + min(position - range.location, replacementRange.length)
            }
            let start = min(adjusted(selection.location), updated.length)
            let end = min(adjusted(NSMaxRange(selection)), updated.length)
            editor.setSelectedRange(NSRange(location: start, length: max(0, end - start)))
        } else {
            text = updatedText
        }
        synchronizeConfigChangeCount()
    }

    private func synchronizeConfigChangeCount() {
        guard kind == .config else { return }
        if !isDocumentEdited {
            updateChangeCount(.changeCleared)
        } else if !super.isDocumentEdited {
            updateChangeCount(.changeDone)
        }
    }

    func textDidChange(_ notification: Notification) {
        guard let textView = notification.object as? NSTextView else { return }
        text = textView.string
        synchronizeConfigChangeCount()
        if kind == .home, let url = fileURL {
            do {
                try Data(text.utf8).write(to: url, options: .atomic)
                updateChangeCount(.changeCleared)
            } catch {
                presentError(error)
            }
        }
    }

    func textView(_ textView: NSTextView, menu: NSMenu, for event: NSEvent, at charIndex: Int) -> NSMenu? {
        // Replace AppKit's system font picker with the same Selected Fonts menu as Format.
        for item in menu.items where item.title == "Font" { menu.removeItem(item) }
        let font = NSMenuItem(title: "Font", action: nil, keyEquivalent: "")
        font.submenu = FontMenu.shared.makeMenu()
        menu.addItem(.separator())
        menu.addItem(font)
        return menu
    }
}
