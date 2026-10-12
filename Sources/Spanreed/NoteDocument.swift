import AppKit

class NoteDocument: NSDocument, NSTextViewDelegate {
    enum Kind { case home, standard, config }

    var kind: Kind = .standard
    private(set) var text = ""
    private(set) var editor: NSTextView?

    override var isDocumentEdited: Bool {
        kind == .home ? false : super.isDocumentEdited
    }

    override class var autosavesInPlace: Bool { false }
    override class var autosavesDrafts: Bool { false }
    override class var preservesVersions: Bool { false }

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
        textView.font = .monospacedSystemFont(ofSize: 20, weight: .regular)
        textView.string = text
        textView.delegate = self
        textView.setAccessibilityIdentifier("note-editor")
        scrollView.documentView = textView
        window.contentView?.addSubview(scrollView)
        editor = textView
        addWindowController(NSWindowController(window: window))
        if kind == .home { window.title = "Home Note" }
        window.makeFirstResponder(textView)
    }

    override func read(from data: Data, ofType typeName: String) throws {
        guard let decoded = String(data: data, encoding: .utf8) else {
            throw NSError(domain: NSCocoaErrorDomain, code: NSFileReadInapplicableStringEncodingError,
                          userInfo: [NSLocalizedDescriptionKey: "This note is not valid UTF-8 text."])
        }
        text = decoded
        editor?.string = decoded
    }

    override func data(ofType typeName: String) throws -> Data {
        Data(text.utf8)
    }

    func textDidChange(_ notification: Notification) {
        guard let textView = notification.object as? NSTextView else { return }
        text = textView.string
        if kind == .home, let url = fileURL {
            do {
                try Data(text.utf8).write(to: url, options: .atomic)
                updateChangeCount(.changeCleared)
            } catch {
                presentError(error)
            }
        }
    }
}
