# Removing the title bar document icon

Research date: 2026-10-12. This note records the investigation before implementation and covers enhancement #1 only.

Removing the icon is feasible with public AppKit APIs. It should be a small change in `NoteWindowController`, with most of the effort spent checking document lifecycle and title bar layout.

## What creates the icon

Spanreed creates native `NSWindow` instances and attaches its `NoteWindowController` to an `NSDocument`. It does not draw a custom document icon. Its windows have a transparent title bar and use `.fullSizeContentView`. The home note has a custom title, while Config and standard notes use document display names. See [NoteDocument.swift](../../Sources/Spanreed/NoteDocument.swift) and [NoteWindowController.swift](../../Sources/Spanreed/NoteWindowController.swift).

AppKit shows the file's icon when a window has a `representedURL` with a path. That URL also supports the title's Command-click path menu. Apple exposes the icon through the public `standardWindowButton(.documentIconButton)` accessor, which returns an optional `NSButton`. The inherited `isHidden` property hides a view and disables its input events. [representedURL](https://developer.apple.com/documentation/appkit/nswindow/representedurl), [standardWindowButton(_:)](https://developer.apple.com/documentation/appkit/nswindow/standardwindowbutton(_:)), [documentIconButton](https://developer.apple.com/documentation/appkit/nswindow/buttontype/documenticonbutton), [isHidden](https://developer.apple.com/documentation/appkit/nsview/ishidden).

## Recommended approach

Override `synchronizeWindowTitleWithDocumentName()` in the existing window controller, call the superclass implementation, then hide the document icon button. This keeps native filename updates and the represented URL. Apple's title synchronization method updates the title and represented filename from the document. The installed Apple SDK's `NSWindowController.h`, lines 84 through 86, explicitly permits overriding it and says AppKit invokes it for document/title changes, including filename changes. [Title synchronization](https://developer.apple.com/documentation/appkit/nswindowcontroller/synchronizewindowtitlewithdocumentname()).

Applying the change only during window initialization is less reliable. The icon can be absent before document attachment, and later document updates can rebuild native title bar state. The override applies the policy after those updates.

The edited indicator has a separate native mechanism. `NSDocument` calls `setDocumentEdited(_:)` on its controllers as needed, so the proposed title override should leave dirty-state handling intact. [Document edited flag](https://developer.apple.com/documentation/appkit/nswindowcontroller/setdocumentedited(_:)).

## Evidence from the local probe

A temporary isolated Swift/AppKit probe on macOS 26.4.1 used Spanreed's window style without displaying windows or modifying the application. Document attachment produced the expected icon button. Hiding it survived dirty-state updates, a document URL/name change, explicit title synchronization, dark appearance, and resize. The controller override also kept the icon hidden, retained `representedURL`, updated the filename, and retained the edited flag.

This verifies object state on the current macOS version. It does not verify visible spacing, hover behavior, actual Save As, fullscreen transitions, or macOS 13 behavior.

## Behavior and alternatives

The user loses the icon's drag action. Apple documents document-icon dragging as a native window interaction. The title's Command-click path menu should remain because the represented URL remains, but this is an inference from the documented title behavior and still needs an interactive check. [Document icon dragging](https://developer.apple.com/documentation/appkit/nswindowdelegate/window(_:shoulddragdocumentwith:from:with:)), [representedURL](https://developer.apple.com/documentation/appkit/nswindow/representedurl).

Clearing `representedURL` after title synchronization is a public-API fallback. It removes the icon and the native path menu. The probe confirmed that clearing it removes the button, while a later superclass synchronization recreates it. It would therefore need the same lifecycle handling. The SDK's `NSWindow.h`, lines 328 through 333, explicitly describes the absence of both icon and path menu when the URL is nil or its path is empty.

Private title bar classes, subview searches, and a custom replacement title bar are unnecessary for this change.

## Effort and remaining checks

Estimate: 30 to 60 minutes for the change, about 1 to 2 hours including focused verification. This assumes hiding the native button leaves acceptable title spacing. Check saved and unsaved notes, home and Config titles, dirty/clean transitions, Save As, document renaming, narrow windows, hover, fullscreen, and the Command-click menu. Check macOS 13 when an environment is available, since the local probe only covers the current OS.
