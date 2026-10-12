import AppKit
import XCTest

func withPreservedPasteboard(_ paste: (NSPasteboard) -> Void) {
    let pasteboard = NSPasteboard.general
    let previousItems = pasteboard.pasteboardItems?.map { original -> NSPasteboardItem in
        let copy = NSPasteboardItem()
        for type in original.types {
            if let data = original.data(forType: type) { copy.setData(data, forType: type) }
        }
        return copy
    } ?? []
    defer {
        pasteboard.clearContents()
        pasteboard.writeObjects(previousItems)
    }
    pasteboard.clearContents()
    paste(pasteboard)
}

extension XCUIApplication {
    func pasteText(_ text: String) {
        withPreservedPasteboard { pasteboard in
            pasteboard.setString(text, forType: .string)
            typeKey("v", modifierFlags: .command)
        }
    }
}
