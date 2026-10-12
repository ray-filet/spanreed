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

    private func openNote(_ url: URL) throws {
        application.typeKey("o", modifierFlags: .command)
        XCTAssertTrue(application.buttons["OKButton"].waitForExistence(timeout: 5))
        application.typeKey("g", modifierFlags: [.command, .shift])
        application.typeKey("a", modifierFlags: .command)
        application.typeText(url.path)
        application.typeKey(.return, modifierFlags: [])
        application.buttons["OKButton"].click()
        XCTAssertTrue(application.windows[url.lastPathComponent].waitForExistence(timeout: 5))
    }
}
