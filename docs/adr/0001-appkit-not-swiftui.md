# Build on AppKit, not SwiftUI

Spanreed uses AppKit (`NSDocument` + `NSTextView`) rather than SwiftUI's `DocumentGroup`. On macOS, `DocumentGroup` opens to a file browser at launch, the TextEdit behavior Spanreed exists to avoid. Working around it is awkward. AppKit gives us direct control over launch, autosave, and window behavior, and `NSTextView` already provides undo and find-and-replace.
