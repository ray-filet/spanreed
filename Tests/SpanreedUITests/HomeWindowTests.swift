import AppKit
import XCTest

final class HomeWindowTests: XCTestCase {
    private var application: XCUIApplication!
    private var testFolder: URL!
    private var defaultsSuite: String!

    override func setUpWithError() throws {
        continueAfterFailure = false
        testFolder = FileManager.default.temporaryDirectory.appendingPathComponent("SpanreedHomeWindowTests-\(UUID().uuidString)")
        application = XCUIApplication()
        application.launchArguments = ["--home-note-folder", testFolder.appendingPathComponent("Home").path,
                                       "--config-folder", testFolder.appendingPathComponent("Config").path]
        defaultsSuite = "SpanreedHomeWindowTests.\(UUID().uuidString)"
        application.launchEnvironment["SPANREED_DEFAULTS_SUITE"] = defaultsSuite
    }

    override func tearDownWithError() throws {
        application.terminate()
        UserDefaults(suiteName: defaultsSuite)?.removePersistentDomain(forName: defaultsSuite)
        try? FileManager.default.removeItem(at: testFolder)
    }

    func testCommandOneReopensClosedHomeNoteWithItsText() throws {
        application.launch()
        XCTAssertTrue(application.textViews["note-editor"].waitForExistence(timeout: 5))
        application.typeText("Bring back this Home Note")
        application.typeKey("w", modifierFlags: .command)
        XCTAssertEqual(application.windows.count, 0)
        XCTAssertEqual(application.state, .runningForeground)
        application.typeKey("1", modifierFlags: .command)
        let homeWindow = application.windows["Home Note"]
        XCTAssertTrue(homeWindow.waitForExistence(timeout: 5))
        XCTAssertEqual(homeWindow.textViews["note-editor"].value as? String, "Bring back this Home Note")
        XCTAssertEqual(application.windows.count, 1)
        application.menuBars.menuBarItems["Window"].click()
        XCTAssertTrue(application.menuItems["Home Note"].exists)
        application.typeKey(.escape, modifierFlags: [])
    }

    func testCommandOneBringsExistingHomeNoteInFrontWithoutDuplicatingIt() throws {
        application.launch()
        XCTAssertTrue(application.textViews["note-editor"].waitForExistence(timeout: 5))
        application.typeText("Home text")
        application.typeKey("n", modifierFlags: .command)
        XCTAssertEqual(application.windows.count, 2)
        application.typeKey("1", modifierFlags: .command)
        application.typeText(" is in front")
        XCTAssertEqual(application.windows.count, 2)
        XCTAssertEqual(application.windows.matching(identifier: "Home Note").count, 1)
        XCTAssertEqual(application.windows["Home Note"].textViews["note-editor"].value as? String, "Home text is in front")
        XCTAssertEqual(try String(contentsOf: homeNoteURL, encoding: .utf8), "Home text is in front")
    }

    func testDockClickReopensHomeNoteAfterLastWindowCloses() throws {
        application.launch()
        XCTAssertTrue(application.textViews["note-editor"].waitForExistence(timeout: 5))
        application.typeText("Dock reopening keeps this text")
        application.typeKey("w", modifierFlags: .command)
        XCTAssertEqual(application.windows.count, 0)
        XCTAssertEqual(application.state, .runningForeground)
        let dock = XCUIApplication(bundleIdentifier: "com.apple.dock")
        let icon = dock.dockItems["Spanreed"]
        XCTAssertTrue(icon.waitForExistence(timeout: 5))
        if !icon.isHittable {
            let app = application!
            addTeardownBlock {
                app.activate()
                app.typeKey("d", modifierFlags: [.command, .option])
            }
            application.typeKey("d", modifierFlags: [.command, .option])
            let visible = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in icon.isHittable }, object: nil)
            XCTAssertEqual(XCTWaiter.wait(for: [visible], timeout: 5), .completed)
        }
        icon.click()
        let homeWindow = application.windows["Home Note"]
        XCTAssertTrue(homeWindow.waitForExistence(timeout: 5))
        XCTAssertEqual(homeWindow.textViews["note-editor"].value as? String, "Dock reopening keeps this text")
        XCTAssertEqual(application.windows.count, 1)
    }

    func testHomeNoteWindowKeepsItsMovedAndResizedFrameAfterRelaunch() throws {
        application.launch()
        let homeWindow = application.windows["Home Note"]
        XCTAssertTrue(homeWindow.waitForExistence(timeout: 5))
        let originalFrame = homeWindow.frame
        let titleBar = homeWindow.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0))
            .withOffset(CGVector(dx: 0, dy: 14))
        titleBar.click(forDuration: 0.2, thenDragTo: titleBar.withOffset(CGVector(dx: 45, dy: 40)))
        let resizeCorner = homeWindow.coordinate(withNormalizedOffset: CGVector(dx: 1, dy: 1))
            .withOffset(CGVector(dx: -2, dy: -2))
        resizeCorner.click(forDuration: 0.2, thenDragTo: resizeCorner.withOffset(CGVector(dx: -90, dy: -70)))
        let changedFrame = homeWindow.frame
        XCTAssertGreaterThan(abs(changedFrame.minX - originalFrame.minX), 20)
        XCTAssertGreaterThan(abs(changedFrame.minY - originalFrame.minY), 20)
        XCTAssertGreaterThan(abs(changedFrame.width - originalFrame.width), 40)
        XCTAssertGreaterThan(abs(changedFrame.height - originalFrame.height), 40)
        application.typeKey("q", modifierFlags: .command)
        XCTAssertTrue(application.wait(for: .notRunning, timeout: 5))
        application.launch()
        XCTAssertTrue(homeWindow.waitForExistence(timeout: 5))
        let restoredFrame = homeWindow.frame
        XCTAssertEqual(restoredFrame.minX, changedFrame.minX, accuracy: 1)
        XCTAssertEqual(restoredFrame.minY, changedFrame.minY, accuracy: 1)
        XCTAssertEqual(restoredFrame.width, changedFrame.width, accuracy: 1)
        XCTAssertEqual(restoredFrame.height, changedFrame.height, accuracy: 1)
    }

    func testHomeNoteSaveAsWritesSnapshotAndKeepsAutosavingOriginal() throws {
        application.launch()
        let homeWindow = application.windows["Home Note"]
        XCTAssertTrue(homeWindow.waitForExistence(timeout: 5))
        application.typeText("Saved snapshot")
        application.typeKey("s", modifierFlags: [.command, .shift])
        let savePanel = homeWindow.sheets.firstMatch
        XCTAssertTrue(savePanel.waitForExistence(timeout: 5))
        application.typeKey("g", modifierFlags: [.command, .shift])
        application.typeKey("a", modifierFlags: .command)
        application.typeText(testFolder.path)
        application.typeKey(.return, modifierFlags: [])
        let filename = savePanel.textFields["saveAsNameTextField"]
        XCTAssertTrue(filename.waitForExistence(timeout: 5))
        filename.click()
        application.typeKey("a", modifierFlags: .command)
        filename.typeText("Snapshot.txt")
        savePanel.buttons["OKButton"].click()
        let copyURL = testFolder.appendingPathComponent("Snapshot.txt")
        XCTAssertTrue(waitForFile(copyURL, containing: "Saved snapshot"))
        application.typeText(" and more Home text")
        XCTAssertEqual(try String(contentsOf: homeNoteURL, encoding: .utf8), "Saved snapshot and more Home text")
        XCTAssertEqual(try String(contentsOf: copyURL, encoding: .utf8), "Saved snapshot")
        XCTAssertEqual(application.windows["Home Note"].textViews["note-editor"].value as? String,
                       "Saved snapshot and more Home text")
    }

    func testOpeningClosedHomeNoteThroughFileMenuRetainsHomeBehavior() throws {
        application.launch()
        XCTAssertTrue(application.textViews["note-editor"].waitForExistence(timeout: 5))
        application.typeText("Opened again")
        application.typeKey("w", modifierFlags: .command)
        application.typeKey("o", modifierFlags: .command)
        let openButton = application.buttons["OKButton"]
        XCTAssertTrue(openButton.waitForExistence(timeout: 5))
        application.typeKey("g", modifierFlags: [.command, .shift])
        application.typeKey("a", modifierFlags: .command)
        application.typeText(homeNoteURL.path)
        application.typeKey(.return, modifierFlags: [])
        openButton.click()
        let editor = application.textViews["note-editor"]
        XCTAssertTrue(editor.waitForExistence(timeout: 5))
        XCTAssertEqual(editor.value as? String, "Opened again")
        application.typeText(" and autosaved")
        XCTAssertTrue(waitForFile(homeNoteURL, containing: "Opened again and autosaved"))
        application.typeKey("1", modifierFlags: .command)
        XCTAssertEqual(application.windows.count, 1)
        XCTAssertTrue(application.windows["Home Note"].exists)
    }

    private func waitForFile(_ url: URL, containing text: String) -> Bool {
        let saved = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
            (try? String(contentsOf: url, encoding: .utf8)) == text
        }, object: nil)
        return XCTWaiter.wait(for: [saved], timeout: 5) == .completed
    }

    private var homeNoteURL: URL { testFolder.appendingPathComponent("Home/Home.txt") }
}
