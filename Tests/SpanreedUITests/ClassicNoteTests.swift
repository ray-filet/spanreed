import AppKit
import XCTest

final class ClassicNoteTests: XCTestCase {
    private var application: XCUIApplication!
    private var testFolder: URL!
    private var defaultsSuite: String!

    override func setUpWithError() throws {
        continueAfterFailure = false
        testFolder = FileManager.default.temporaryDirectory.appendingPathComponent("SpanreedClassicTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: testFolder, withIntermediateDirectories: true)
        application = XCUIApplication()
        application.launchArguments = ["--home-note-folder", testFolder.appendingPathComponent("Home").path,
                                       "--config-folder", testFolder.appendingPathComponent("Config").path]
        defaultsSuite = "SpanreedClassicTests.\(UUID().uuidString)"
        application.launchEnvironment["SPANREED_DEFAULTS_SUITE"] = defaultsSuite
    }

    override func tearDownWithError() throws {
        application.terminate()
        UserDefaults(suiteName: defaultsSuite)?.removePersistentDomain(forName: defaultsSuite)
        try? FileManager.default.removeItem(at: testFolder)
    }

    func testNewUntitledNotePromptsBeforeDiscardingText() throws {
        application.launch()
        XCTAssertTrue(application.windows["Home Note"].waitForExistence(timeout: 5))
        application.typeKey("n", modifierFlags: .command)
        let untitled = application.windows.matching(NSPredicate(format: "title BEGINSWITH %@", "Untitled")).firstMatch
        XCTAssertTrue(untitled.waitForExistence(timeout: 5))
        application.typeText("Keep this note until I decide")
        application.typeKey("w", modifierFlags: .command)
        let save = untitled.sheets.buttons["Save"]
        XCTAssertTrue(save.waitForExistence(timeout: 5))
        XCTAssertTrue(untitled.sheets.buttons["Cancel"].exists)
        untitled.sheets.buttons["Cancel"].click()
        XCTAssertEqual(untitled.textViews["note-editor"].value as? String, "Keep this note until I decide")
        application.typeKey("w", modifierFlags: .command)
        untitled.sheets.buttons["DontSaveButton"].click()
        XCTAssertEqual(application.windows.count, 1)
    }

    func testOpenedFileCanBeReopenedThroughOpenRecent() throws {
        let url = testFolder.appendingPathComponent("Recent note.txt")
        try "A recently opened note".write(to: url, atomically: true, encoding: .utf8)
        application.launch()
        try openNote(url)
        XCTAssertEqual(application.windows[url.lastPathComponent].textViews["note-editor"].value as? String,
                       "A recently opened note")
        application.typeKey("w", modifierFlags: .command)
        let fileMenu = application.menuBars.menuBarItems["File"]
        fileMenu.click()
        let openRecent = fileMenu.menuItems["Open Recent"]
        XCTAssertTrue(openRecent.waitForExistence(timeout: 3))
        XCTAssertEqual(fileMenu.menuItems.matching(identifier: "Open Recent").count, 1)
        openRecent.click()
        let recent = openRecent.menuItems[url.lastPathComponent]
        XCTAssertTrue(recent.waitForExistence(timeout: 3))
        recent.click()
        let reopened = application.windows[url.lastPathComponent]
        XCTAssertTrue(reopened.waitForExistence(timeout: 5))
        XCTAssertEqual(reopened.textViews["note-editor"].value as? String, "A recently opened note")
    }

    func testOpenedNoteWritesUTF8OnlyWhenSavedAndClosesWithoutPromptAfterSaving() throws {
        let url = testFolder.appendingPathComponent("Saved note.txt")
        let original = "Café 日本"
        try original.write(to: url, atomically: true, encoding: .utf8)
        application.launch()
        try openNote(url)
        let note = application.windows[url.lastPathComponent]
        XCTAssertEqual(note.textViews["note-editor"].value as? String, original)
        application.typeKey(.downArrow, modifierFlags: .command)
        application.typeText("\nA manual save")
        XCTAssertEqual(try String(contentsOf: url, encoding: .utf8), original)
        attachScreenshot(named: "Classic note with unsaved changes")
        application.typeKey("s", modifierFlags: .command)
        let saved = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
            (try? String(contentsOf: url, encoding: .utf8)) == "Café 日本\nA manual save"
        }, object: nil)
        XCTAssertEqual(XCTWaiter.wait(for: [saved], timeout: 5), .completed)
        attachScreenshot(named: "Classic note after saving")
        application.typeKey("w", modifierFlags: .command)
        XCTAssertFalse(note.exists)
        XCTAssertEqual(application.windows.count, 1)
        XCTAssertFalse(application.sheets.firstMatch.exists)
    }

    func testOpenAcceptsTextMarkdownAndLogNotesWithNonASCIIText() throws {
        application.launch()
        for ext in ["txt", "md", "log"] {
            let url = testFolder.appendingPathComponent("UTF8 note.\(ext)")
            let text = "Café 日本 in a .\(ext) note"
            try text.write(to: url, atomically: true, encoding: .utf8)
            try openNote(url)
            XCTAssertEqual(application.windows[url.lastPathComponent].textViews["note-editor"].value as? String, text)
            application.typeKey("w", modifierFlags: .command)
            XCTAssertEqual(application.windows.count, 1)
        }
    }

    func testInvalidUTF8ShowsAnErrorWithoutOpeningOrChangingTheFile() throws {
        let url = testFolder.appendingPathComponent("Invalid UTF8.txt")
        let bytes = Data([0x66, 0x6f, 0x80, 0xff])
        try bytes.write(to: url)
        application.launch()
        try chooseNoteInOpenPanel(url)
        attachScreenshot(named: "Rejected invalid UTF-8 note")
        let errorAlert = application.dialogs.firstMatch
        XCTAssertTrue(errorAlert.waitForExistence(timeout: 5))
        XCTAssertTrue((errorAlert.staticTexts.firstMatch.value as? String)?.contains("could not be opened") == true)
        XCTAssertEqual(application.textViews.matching(identifier: "note-editor").count, 1)
        application.typeKey(.return, modifierFlags: [])
        XCTAssertEqual(application.windows.count, 1)
        XCTAssertTrue(application.windows["Home Note"].exists)
        XCTAssertEqual(try Data(contentsOf: url), bytes)
    }

    func testSaveAsMovesClassicNoteToItsNewLocationForLaterSaves() throws {
        let original = testFolder.appendingPathComponent("Original note.txt")
        let renamed = testFolder.appendingPathComponent("Renamed note.txt")
        try "Original location".write(to: original, atomically: true, encoding: .utf8)
        application.launch()
        try openNote(original)
        application.typeKey(.downArrow, modifierFlags: .command)
        application.typeText("\nBefore Save As")
        application.typeKey("s", modifierFlags: [.command, .shift])
        let savePanel = application.windows[original.lastPathComponent].sheets.firstMatch
        XCTAssertTrue(savePanel.waitForExistence(timeout: 5))
        application.typeKey("g", modifierFlags: [.command, .shift])
        application.typeKey("a", modifierFlags: .command)
        application.typeText(testFolder.path)
        application.typeKey(.return, modifierFlags: [])
        let name = savePanel.textFields["saveAsNameTextField"]
        name.click()
        application.typeKey("a", modifierFlags: .command)
        name.typeText(renamed.lastPathComponent)
        savePanel.buttons["OKButton"].click()
        XCTAssertTrue(application.windows[renamed.lastPathComponent].waitForExistence(timeout: 5))
        XCTAssertEqual(try String(contentsOf: original, encoding: .utf8), "Original location")
        XCTAssertEqual(try String(contentsOf: renamed, encoding: .utf8), "Original location\nBefore Save As")
        application.typeKey(.downArrow, modifierFlags: .command)
        application.typeText("\nAfter Save As")
        application.typeKey("s", modifierFlags: .command)
        let saved = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
            (try? String(contentsOf: renamed, encoding: .utf8)) == "Original location\nBefore Save As\nAfter Save As"
        }, object: nil)
        XCTAssertEqual(XCTWaiter.wait(for: [saved], timeout: 5), .completed)
        XCTAssertEqual(try String(contentsOf: original, encoding: .utf8), "Original location")
    }

    func testQuitPromptsForDirtyClassicNoteAndRelaunchShowsOnlyHomeNote() throws {
        let url = testFolder.appendingPathComponent("Quit note.txt")
        try "A saved classic note".write(to: url, atomically: true, encoding: .utf8)
        application.launch()
        XCTAssertTrue(application.textViews["note-editor"].waitForExistence(timeout: 5))
        application.typeText("The Home Note survives quitting")
        try openNote(url)
        let note = application.windows[url.lastPathComponent]
        application.typeKey(.downArrow, modifierFlags: .command)
        application.typeText("\nAn unsaved edit")
        application.typeKey("q", modifierFlags: .command)
        let save = note.sheets.buttons["Save"]
        XCTAssertTrue(save.waitForExistence(timeout: 5))
        XCTAssertEqual(application.sheets.count, 1)
        XCTAssertEqual(try String(contentsOf: url, encoding: .utf8), "A saved classic note")
        attachScreenshot(named: "Quit prompt for the classic note")
        save.click()
        XCTAssertTrue(application.wait(for: .notRunning, timeout: 5))
        XCTAssertEqual(try String(contentsOf: url, encoding: .utf8), "A saved classic note\nAn unsaved edit")
        XCTAssertEqual(try String(contentsOf: testFolder.appendingPathComponent("Home/Home.txt"), encoding: .utf8),
                       "The Home Note survives quitting")
        application.launch()
        let editor = application.textViews["note-editor"]
        XCTAssertTrue(editor.waitForExistence(timeout: 5))
        XCTAssertEqual(application.windows.count, 1)
        XCTAssertEqual(editor.value as? String, "The Home Note survives quitting")
    }

    func testUndoToSavedContentsClearsUnsavedChanges() throws {
        let url = testFolder.appendingPathComponent("Undo note.txt")
        try "Clean contents".write(to: url, atomically: true, encoding: .utf8)
        application.launch()
        try openNote(url)
        let note = application.windows[url.lastPathComponent]
        application.typeKey(.downArrow, modifierFlags: .command)
        application.typeText(" plus unsaved text")
        application.typeKey("z", modifierFlags: .command)
        XCTAssertEqual(note.textViews["note-editor"].value as? String, "Clean contents")
        application.typeKey("w", modifierFlags: .command)
        XCTAssertFalse(note.exists)
        XCTAssertFalse(application.sheets.firstMatch.exists)
        XCTAssertEqual(try String(contentsOf: url, encoding: .utf8), "Clean contents")
    }

    private func attachScreenshot(named name: String) {
        let screenshot = XCTAttachment(screenshot: application.screenshot())
        screenshot.name = name
        screenshot.lifetime = .keepAlways
        add(screenshot)
    }

    private func openNote(_ url: URL) throws {
        try chooseNoteInOpenPanel(url)
        XCTAssertTrue(application.windows[url.lastPathComponent].waitForExistence(timeout: 5))
    }

    private func chooseNoteInOpenPanel(_ url: URL) throws {
        application.typeKey("o", modifierFlags: .command)
        XCTAssertTrue(application.buttons["OKButton"].waitForExistence(timeout: 5))
        application.typeKey("g", modifierFlags: [.command, .shift])
        application.typeKey("a", modifierFlags: .command)
        application.typeText(url.path)
        application.typeKey(.return, modifierFlags: [])
        application.buttons["OKButton"].click()
    }
}
