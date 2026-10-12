import AppKit
import XCTest

final class TextSizeTests: XCTestCase {
    private var application: XCUIApplication!
    private var testFolder: URL!
    private var defaultsSuite: String!
    private let noteText = String(repeating: "A readable note\n", count: 50)

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
        let homeEditor = application.windows.matching(NSPredicate(format: "title == %@ OR title == %@", "Home.txt", "Home Note"))
            .firstMatch.textViews["note-editor"]
        let defaultHeight = homeEditor.frame.height
        let defaultScreenshot = XCTAttachment(screenshot: application.screenshot())
        defaultScreenshot.name = "Default SF Mono at 20 points"
        defaultScreenshot.lifetime = .keepAlways
        add(defaultScreenshot)

        application.typeKey("n", modifierFlags: .command)
        let untitledEditor = application.windows["Untitled"].textViews["note-editor"]
        XCTAssertTrue(untitledEditor.waitForExistence(timeout: 5))
        paste(noteText)
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

    func testZoomAndResetAreRememberedAcrossLaunches() throws {
        application.launch()
        XCTAssertTrue(application.textViews["note-editor"].waitForExistence(timeout: 5))
        let defaultHeight = application.textViews["note-editor"].frame.height
        application.typeKey("=", modifierFlags: [.command, .shift])
        application.typeKey("=", modifierFlags: [.command, .shift])
        application.typeKey("=", modifierFlags: [.command, .shift])
        let enlargedHeight = application.textViews["note-editor"].frame.height
        XCTAssertGreaterThan(enlargedHeight, defaultHeight)
        application.typeKey("q", modifierFlags: .command)
        XCTAssertTrue(application.wait(for: .notRunning, timeout: 5))

        application.launch()
        XCTAssertTrue(application.textViews["note-editor"].waitForExistence(timeout: 5))
        XCTAssertEqual(application.textViews["note-editor"].frame.height, enlargedHeight, accuracy: 1)
        application.typeKey("0", modifierFlags: .command)
        XCTAssertEqual(application.textViews["note-editor"].frame.height, defaultHeight, accuracy: 1)
        application.typeKey("q", modifierFlags: .command)
        XCTAssertTrue(application.wait(for: .notRunning, timeout: 5))

        application.launch()
        XCTAssertTrue(application.textViews["note-editor"].waitForExistence(timeout: 5))
        XCTAssertEqual(application.textViews["note-editor"].frame.height, defaultHeight, accuracy: 1)
    }

    private func paste(_ text: String) {
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
        pasteboard.setString(text, forType: .string)
        application.typeKey("v", modifierFlags: .command)
    }
}
