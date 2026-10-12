import AppKit
import XCTest

final class TextSizeTests: XCTestCase {
    private var application: XCUIApplication!
    private var testFolder: URL!
    private var defaultsSuite: String!
    private let noteText = String(repeating: "A readable note\n", count: 50)
    private var configURL: URL { testFolder.appendingPathComponent("Config/config") }

    override func setUpWithError() throws {
        continueAfterFailure = false
        testFolder = FileManager.default.temporaryDirectory.appendingPathComponent("SpanreedTextSizeTests-\(UUID().uuidString)")
        application = XCUIApplication()
        application.launchArguments = ["--home-note-folder", testFolder.appendingPathComponent("Home").path,
                                       "--config-folder", testFolder.appendingPathComponent("Config").path]
        defaultsSuite = "SpanreedTextSizeTests.\(UUID().uuidString)"
        application.launchEnvironment["SPANREED_DEFAULTS_SUITE"] = defaultsSuite
        try FileManager.default.createDirectory(at: testFolder.appendingPathComponent("Home"), withIntermediateDirectories: true)
        try noteText.write(to: testFolder.appendingPathComponent("Home/Home.txt"), atomically: true, encoding: .utf8)
    }

    override func tearDownWithError() throws {
        application.terminate()
        UserDefaults(suiteName: defaultsSuite)?.removePersistentDomain(forName: defaultsSuite)
        try? FileManager.default.removeItem(at: testFolder)
    }

    func testZoomShortcutsAndMenusChangeEveryOpenNote() throws {
        application.launch()
        XCTAssertTrue(application.textViews["note-editor"].waitForExistence(timeout: 5))
        let homeEditor = application.windows["home"].textViews["note-editor"]
        let defaultHeight = homeEditor.frame.height
        let defaultScreenshot = XCTAttachment(screenshot: application.screenshot())
        defaultScreenshot.name = "Default SF Mono at 20 points"
        defaultScreenshot.lifetime = .keepAlways
        add(defaultScreenshot)

        application.typeKey("n", modifierFlags: .command)
        let untitledEditor = application.windows["Untitled"].textViews["note-editor"]
        XCTAssertTrue(untitledEditor.waitForExistence(timeout: 5))
        application.pasteText(noteText)
        XCTAssertEqual(untitledEditor.frame.height, defaultHeight, accuracy: 1)

        application.menuBars.menuBarItems["View"].click()
        XCTAssertTrue(application.menuItems["Increase Text Size"].exists)
        XCTAssertTrue(application.menuItems["Decrease Text Size"].exists)
        XCTAssertTrue(application.menuItems["Reset Text Size"].exists)
        application.typeKey(.escape, modifierFlags: [])
        let dismissedMenu = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
            !self.application.menuItems["Increase Text Size"].isHittable
        }, object: nil)
        XCTAssertEqual(XCTWaiter.wait(for: [dismissedMenu], timeout: 3), .completed)

        application.typeKey("=", modifierFlags: [.command, .shift])
        XCTAssertGreaterThan(untitledEditor.frame.height, defaultHeight)
        XCTAssertEqual(homeEditor.frame.height, untitledEditor.frame.height, accuracy: 1)
        application.typeKey("-", modifierFlags: .command)
        XCTAssertEqual(homeEditor.frame.height, defaultHeight, accuracy: 1)
        XCTAssertEqual(untitledEditor.frame.height, defaultHeight, accuracy: 1)

        application.menuBars.menuBarItems["View"].click()
        application.menuItems["Increase Text Size"].click()
        XCTAssertGreaterThan(homeEditor.frame.height, defaultHeight)
        application.typeKey("0", modifierFlags: .command)
        XCTAssertEqual(homeEditor.frame.height, defaultHeight, accuracy: 1)
        XCTAssertEqual(untitledEditor.frame.height, defaultHeight, accuracy: 1)

        application.typeKey("=", modifierFlags: .command)
        XCTAssertGreaterThan(homeEditor.frame.height, defaultHeight)
        XCTAssertEqual(homeEditor.frame.height, untitledEditor.frame.height, accuracy: 1)
        application.typeKey("0", modifierFlags: .command)
        XCTAssertEqual(homeEditor.frame.height, defaultHeight, accuracy: 1)
    }

    func testZoomUpdatesOpenConfigWithoutSavingUnrelatedEdits() throws {
        application.launch()
        XCTAssertTrue(application.windows["home"].textViews["note-editor"].waitForExistence(timeout: 5))
        application.typeKey(",", modifierFlags: .command)
        let config = application.windows["Config"]
        let editor = config.textViews["note-editor"]
        XCTAssertTrue(editor.waitForExistence(timeout: 5))
        let original = try String(contentsOf: configURL, encoding: .utf8)
        let comment = "# An unfinished Config edit\n"
        application.typeKey(.downArrow, modifierFlags: .command)
        application.pasteText(comment)
        application.typeKey("=", modifierFlags: [.command, .shift])
        let zoomed = original.replacingOccurrences(of: "current-text-size = 20\n", with: "current-text-size = 21.0\n")
        XCTAssertEqual(try String(contentsOf: configURL, encoding: .utf8), zoomed)
        XCTAssertEqual(editor.value as? String, zoomed + comment)
        application.typeKey("z", modifierFlags: .command)
        XCTAssertEqual(editor.value as? String, original + comment)
        XCTAssertEqual(try String(contentsOf: configURL, encoding: .utf8), zoomed)
        application.typeKey("z", modifierFlags: [.command, .shift])
        XCTAssertEqual(editor.value as? String, zoomed + comment)
        application.typeKey("w", modifierFlags: .command)
        XCTAssertTrue(config.sheets.buttons["Save"].waitForExistence(timeout: 5))
        application.typeKey(.escape, modifierFlags: [])
    }

    func testSavingCurrentSizeKeepsTheResetDefaultSeparate() throws {
        application.launch()
        let home = application.windows["home"].textViews["note-editor"]
        XCTAssertTrue(home.waitForExistence(timeout: 5))
        application.typeKey(",", modifierFlags: .command)
        let editor = application.windows["Config"].textViews["note-editor"]
        XCTAssertTrue(editor.waitForExistence(timeout: 5))
        application.typeKey("a", modifierFlags: .command)
        application.pasteText("font-size = 24\ncurrent-text-size = 28\n")
        application.typeKey("s", modifierFlags: .command)
        let zoomedHeight = home.frame.height
        application.typeKey("0", modifierFlags: .command)
        XCTAssertLessThan(home.frame.height, zoomedHeight)
        let text = try String(contentsOf: configURL, encoding: .utf8)
        XCTAssertTrue(text.hasPrefix("font-size = 24\ncurrent-text-size = 24.0\n"), text)
        XCTAssertEqual(editor.value as? String, text)
    }

    func testZoomAndResetAreRememberedAcrossLaunches() throws {
        application.launch()
        XCTAssertTrue(application.textViews["note-editor"].waitForExistence(timeout: 5))
        let defaultHeight = application.textViews["note-editor"].frame.height
        application.typeKey("=", modifierFlags: [.command, .shift])
        application.typeKey("=", modifierFlags: [.command, .shift])
        application.typeKey("=", modifierFlags: [.command, .shift])
        let enlargedHeight = application.textViews["note-editor"].frame.height
        XCTAssertGreaterThan(enlargedHeight, defaultHeight)
        let zoomConfig = try String(contentsOf: configURL, encoding: .utf8)
        XCTAssertTrue(zoomConfig.contains("current-text-size = 23.0"), zoomConfig)
        XCTAssertTrue(zoomConfig.contains("font-size = 20"), zoomConfig)
        XCTAssertNil(UserDefaults(suiteName: defaultsSuite)?.object(forKey: "CurrentTextSize"))
        application.typeKey("q", modifierFlags: .command)
        XCTAssertTrue(application.wait(for: .notRunning, timeout: 5))

        application.launch()
        XCTAssertTrue(application.textViews["note-editor"].waitForExistence(timeout: 5))
        XCTAssertEqual(application.textViews["note-editor"].frame.height, enlargedHeight, accuracy: 1)
        application.typeKey("0", modifierFlags: .command)
        XCTAssertEqual(application.textViews["note-editor"].frame.height, defaultHeight, accuracy: 1)
        XCTAssertTrue(try String(contentsOf: configURL, encoding: .utf8).contains("current-text-size = 20.0"))
        application.typeKey("q", modifierFlags: .command)
        XCTAssertTrue(application.wait(for: .notRunning, timeout: 5))

        application.launch()
        XCTAssertTrue(application.textViews["note-editor"].waitForExistence(timeout: 5))
        XCTAssertEqual(application.textViews["note-editor"].frame.height, defaultHeight, accuracy: 1)
    }
}
