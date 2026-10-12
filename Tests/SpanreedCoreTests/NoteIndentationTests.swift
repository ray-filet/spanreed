import Foundation
import XCTest
@testable import SpanreedCore

final class NoteIndentationTests: XCTestCase {
    func testSelectedLinesLoseOneLevelAndRetainRelativeIndentation() throws {
        let original = "   First\n\t\tNested\n        Spaces\n\n  Short indent\nNo indent"
        let edit = try XCTUnwrap(NoteIndentation.outdent(original, selection: NSRange(location: 0, length: (original as NSString).length)))
        let expected = "First\n\tNested\n    Spaces\n\nShort indent\nNo indent"
        XCTAssertEqual(applying(edit, to: original), expected)
        XCTAssertEqual(edit.selection, NSRange(location: 0, length: (expected as NSString).length))
    }

    func testCaretOutdentsOnlyItsLineAndPreservesItsTextPosition() throws {
        let original = "    First\n    Café 😀\n    Third"
        let caret = NSMaxRange((original as NSString).range(of: "Café 😀"))
        let edit = try XCTUnwrap(NoteIndentation.outdent(original, selection: NSRange(location: caret, length: 0)))
        XCTAssertEqual(applying(edit, to: original), "    First\nCafé 😀\n    Third")
        XCTAssertEqual(edit.selection, NSRange(location: caret - 4, length: 0))
    }

    func testSelectionEndingAtLineStartExcludesThatLine() throws {
        let original = "    First\n    Second\n    Third"
        let thirdStart = (original as NSString).range(of: "    Third").location
        let edit = try XCTUnwrap(NoteIndentation.outdent(original, selection: NSRange(location: 6, length: thirdStart - 6)))
        XCTAssertEqual(applying(edit, to: original), "First\nSecond\n    Third")
        XCTAssertEqual(edit.selection, NSRange(location: 2, length: thirdStart - 10))
    }

    func testCaretInsideRemovedIndentationStaysAtLineStart() throws {
        for caret in 0...4 {
            let edit = try XCTUnwrap(NoteIndentation.outdent("    Line", selection: NSRange(location: caret, length: 0)))
            XCTAssertEqual(applying(edit, to: "    Line"), "Line")
            XCTAssertEqual(edit.selection, NSRange(location: 0, length: 0))
        }
    }

    func testLineEndingsAndUnicodeArePreserved() throws {
        let original = "    😀\r\n\t日本\r    Café\u{2028}    Last\n"
        let edit = try XCTUnwrap(NoteIndentation.outdent(original, selection: NSRange(location: 0, length: (original as NSString).length)))
        XCTAssertEqual(Data(applying(edit, to: original).utf8), Data("😀\r\n日本\rCafé\u{2028}Last\n".utf8))
    }

    func testMixedSpacesAndTabsLoseOneTabStop() throws {
        let original = "  \t\tFirst\n   \tSecond\n     Third\n \n\t"
        let edit = try XCTUnwrap(NoteIndentation.outdent(original, selection: NSRange(location: 0, length: (original as NSString).length)))
        XCTAssertEqual(applying(edit, to: original), "\tFirst\nSecond\n Third\n\n")
    }

    func testUnindentedLinesAndEmptyFinalLineProduceNoEdit() {
        let original = "Text with    spaces\tinside\n\u{00A0}Nonbreaking space\n"
        XCTAssertNil(NoteIndentation.outdent(original, selection: NSRange(location: 0, length: (original as NSString).length)))
        XCTAssertNil(NoteIndentation.outdent(original, selection: NSRange(location: (original as NSString).length, length: 0)))
        XCTAssertNil(NoteIndentation.outdent("", selection: NSRange(location: 0, length: 0)))
    }

    private func applying(_ edit: NoteIndentation.Edit, to text: String) -> String {
        (text as NSString).replacingCharacters(in: edit.range, with: edit.replacement)
    }
}
