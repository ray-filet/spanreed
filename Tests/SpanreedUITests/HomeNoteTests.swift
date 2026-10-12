import AppKit
import XCTest

final class HomeNoteTests: XCTestCase {
    private var application: XCUIApplication!
    private var testFolder: URL!
    private var defaultsSuite: String!

    override func setUpWithError() throws {
        continueAfterFailure = false
        testFolder = FileManager.default.temporaryDirectory.appendingPathComponent("SpanreedUITests-\(UUID().uuidString)")
        application = XCUIApplication()
        application.launchArguments = ["--home-note-folder", testFolder.appendingPathComponent("Home").path,
                                       "--config-folder", testFolder.appendingPathComponent("Config").path]
        defaultsSuite = "SpanreedUITests.\(UUID().uuidString)"
        application.launchEnvironment["SPANREED_DEFAULTS_SUITE"] = defaultsSuite
    }

    override func tearDownWithError() throws {
        application.terminate()
        UserDefaults(suiteName: defaultsSuite)?.removePersistentDomain(forName: defaultsSuite)
        try? FileManager.default.removeItem(at: testFolder)
    }

    func testFirstLaunchCreatesHomeNoteAndFocusesEditor() throws {
        application.launch()
        let editor = application.windows["home"].textViews["note-editor"]
        XCTAssertTrue(editor.waitForExistence(timeout: 5))
        XCTAssertEqual(application.windows.count, 1)
        XCTAssertTrue(FileManager.default.fileExists(atPath: homeNoteURL.path))
        XCTAssertEqual(try String(contentsOf: homeNoteURL, encoding: .utf8), "")
        application.typeText("Ready to type")
        XCTAssertEqual(editor.value as? String, "Ready to type")
    }

    func testTypingAutosavesExactPlainText() throws {
        application.launch()
        XCTAssertTrue(application.textViews["note-editor"].waitForExistence(timeout: 5))
        application.typeText("\"quoted\" -- teh")
        let saved = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
            (try? String(contentsOf: self.homeNoteURL, encoding: .utf8)) == "\"quoted\" -- teh"
        }, object: nil)
        XCTAssertEqual(XCTWaiter.wait(for: [saved], timeout: 4), .completed)
        XCTAssertEqual(try String(contentsOf: homeNoteURL, encoding: .utf8), "\"quoted\" -- teh")
    }

    func testQuitDoesNotPromptAndRelaunchRestoresHomeNoteText() throws {
        application.launch()
        XCTAssertTrue(application.textViews["note-editor"].waitForExistence(timeout: 5))
        application.typeText("A note for the next launch")
        application.typeKey("q", modifierFlags: .command)
        XCTAssertTrue(application.wait(for: .notRunning, timeout: 5))
        application.launch()
        let editor = application.textViews["note-editor"]
        XCTAssertTrue(editor.waitForExistence(timeout: 5))
        XCTAssertEqual(editor.value as? String, "A note for the next launch")
        XCTAssertEqual(application.windows.count, 1)
    }

    func testDeletedHomeNoteIsRecreatedEmptyOnNextLaunch() throws {
        application.launch()
        XCTAssertTrue(application.textViews["note-editor"].waitForExistence(timeout: 5))
        application.typeText("This Home Note will be moved")
        application.typeKey("q", modifierFlags: .command)
        XCTAssertTrue(application.wait(for: .notRunning, timeout: 5))
        try FileManager.default.moveItem(at: homeNoteURL, to: testFolder.appendingPathComponent("Moved.txt"))
        application.launch()
        let editor = application.textViews["note-editor"]
        XCTAssertTrue(editor.waitForExistence(timeout: 5))
        XCTAssertEqual(editor.value as? String, "")
        XCTAssertEqual(try String(contentsOf: homeNoteURL, encoding: .utf8), "")
    }

    func testUndoAndRedoAlsoAutosaveHomeNote() throws {
        application.launch()
        let editor = application.textViews["note-editor"]
        XCTAssertTrue(editor.waitForExistence(timeout: 5))
        application.typeText("Undo this typing")
        application.typeKey("z", modifierFlags: .command)
        XCTAssertEqual(editor.value as? String, "")
        XCTAssertEqual(try String(contentsOf: homeNoteURL, encoding: .utf8), "")
        application.typeKey("z", modifierFlags: [.command, .shift])
        XCTAssertEqual(editor.value as? String, "Undo this typing")
        XCTAssertEqual(try String(contentsOf: homeNoteURL, encoding: .utf8), "Undo this typing")
    }

    func testFindAndReplaceIsAvailableThroughKeyboardShortcuts() throws {
        application.launch()
        XCTAssertTrue(application.textViews["note-editor"].waitForExistence(timeout: 5))
        application.typeText("Find this phrase")
        application.typeKey("f", modifierFlags: .command)
        XCTAssertTrue(application.searchFields.firstMatch.waitForExistence(timeout: 5))
        application.searchFields.firstMatch.typeText("phrase")
        application.checkBoxes["Replace"].click()
        let replacement = application.textFields.matching(NSPredicate(format: "placeholderValue == %@", "Replace")).firstMatch
        XCTAssertTrue(replacement.waitForExistence(timeout: 5))
        replacement.click()
        replacement.typeText("sentence")
        application.buttons["All"].click()
        XCTAssertEqual(try String(contentsOf: homeNoteURL, encoding: .utf8), "Find this sentence")
    }

    func testFormattedPasteIsPlainTextAndLongLinesWrap() throws {
        application.launch()
        let editor = application.textViews["note-editor"]
        XCTAssertTrue(editor.waitForExistence(timeout: 5))
        let longText = String(repeating: "A long plain text line ", count: 120)
        withPreservedPasteboard { pasteboard in
            let formattedItem = NSPasteboardItem()
            formattedItem.setString(longText, forType: .string)
            formattedItem.setData(Data("{\\rtf1\\ansi\\b \(longText)\\b0}".utf8), forType: .rtf)
            pasteboard.writeObjects([formattedItem])
            application.typeKey("v", modifierFlags: .command)
        }
        XCTAssertEqual(editor.value as? String, longText)
        XCTAssertEqual(try String(contentsOf: homeNoteURL, encoding: .utf8), longText)
        XCTAssertGreaterThan(editor.frame.height, application.windows.firstMatch.frame.height)
        for scrollbar in application.scrollBars.allElementsBoundByIndex {
            XCTAssertGreaterThan(scrollbar.frame.height, scrollbar.frame.width)
        }
        let screenshot = XCTAttachment(screenshot: application.screenshot())
        screenshot.name = "Wrapped plain text paste"
        screenshot.lifetime = .keepAlways
        add(screenshot)
    }

    private var homeNoteURL: URL { testFolder.appendingPathComponent("Home/Home.txt") }
}
