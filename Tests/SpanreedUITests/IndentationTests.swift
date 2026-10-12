import AppKit
import XCTest

final class IndentationTests: XCTestCase {
    private var application: XCUIApplication!
    private var testFolder: URL!
    private var defaultsSuite: String!

    override func setUpWithError() throws {
        continueAfterFailure = false
        testFolder = FileManager.default.temporaryDirectory.appendingPathComponent("SpanreedIndentationTests-\(UUID().uuidString)")
        application = XCUIApplication()
        application.launchArguments = ["--home-note-folder", testFolder.appendingPathComponent("Home").path,
                                       "--config-folder", testFolder.appendingPathComponent("Config").path]
        defaultsSuite = "SpanreedIndentationTests.\(UUID().uuidString)"
        application.launchEnvironment["SPANREED_DEFAULTS_SUITE"] = defaultsSuite
    }

    override func tearDownWithError() throws {
        application.terminate()
        UserDefaults(suiteName: defaultsSuite)?.removePersistentDomain(forName: defaultsSuite)
        try? FileManager.default.removeItem(at: testFolder)
    }

    func testShiftTabOutdentsSelectedLinesAndAutosavesAsOneUndoableEdit() throws {
        application.launch()
        let editor = application.windows["home"].textViews["note-editor"]
        XCTAssertTrue(editor.waitForExistence(timeout: 5))
        let original = "   First line\n\n\t\tNested line\n      Spaces\nNo indentation"
        let expected = "First line\n\n\tNested line\n  Spaces\nNo indentation"
        application.pasteText(original)
        application.typeKey("a", modifierFlags: .command)
        application.typeKey(.tab, modifierFlags: .shift)
        XCTAssertEqual(editor.value as? String, expected)
        XCTAssertEqual(try String(contentsOf: homeNoteURL, encoding: .utf8), expected)

        application.typeKey("z", modifierFlags: .command)
        XCTAssertEqual(editor.value as? String, original)
        XCTAssertEqual(try String(contentsOf: homeNoteURL, encoding: .utf8), original)
        application.typeKey("z", modifierFlags: [.command, .shift])
        XCTAssertEqual(editor.value as? String, expected)
        XCTAssertEqual(try String(contentsOf: homeNoteURL, encoding: .utf8), expected)
    }

    func testTabAndShiftTabAtCaretKeepEditorFocused() throws {
        application.launch()
        let editor = application.windows["home"].textViews["note-editor"]
        XCTAssertTrue(editor.waitForExistence(timeout: 5))
        application.typeKey(.tab, modifierFlags: [])
        application.typeText("Line")
        XCTAssertEqual(editor.value as? String, "\tLine")
        application.typeKey(.tab, modifierFlags: .shift)
        XCTAssertEqual(editor.value as? String, "Line")
        application.typeKey(.tab, modifierFlags: .shift)
        application.typeText(" still focused")
        XCTAssertEqual(editor.value as? String, "Line still focused")
    }

    func testRepeatedShiftTabKeepsTheSameLinesSelected() throws {
        application.launch()
        let editor = application.windows["home"].textViews["note-editor"]
        XCTAssertTrue(editor.waitForExistence(timeout: 5))
        application.pasteText("        First\n\t\tSecond")
        application.typeKey("a", modifierFlags: .command)
        application.typeKey(.tab, modifierFlags: .shift)
        XCTAssertEqual(editor.value as? String, "    First\n\tSecond")
        application.typeKey(.tab, modifierFlags: .shift)
        XCTAssertEqual(editor.value as? String, "First\nSecond")
    }

    private var homeNoteURL: URL { testFolder.appendingPathComponent("Home/Home.txt") }
}
