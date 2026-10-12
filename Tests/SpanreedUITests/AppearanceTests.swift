import AppKit
import XCTest

final class AppearanceTests: XCTestCase {
    private var application: XCUIApplication!
    private var testFolder: URL!
    private var defaultsSuite: String!
    private var configURL: URL { testFolder.appendingPathComponent("Config/config") }

    override func setUpWithError() throws {
        continueAfterFailure = false
        testFolder = FileManager.default.temporaryDirectory.appendingPathComponent("SpanreedAppearanceTests-\(UUID().uuidString)")
        defaultsSuite = "SpanreedAppearanceTests.\(UUID().uuidString)"
        application = XCUIApplication()
        application.launchArguments = ["--home-note-folder", testFolder.appendingPathComponent("Home").path,
                                       "--config-folder", testFolder.appendingPathComponent("Config").path]
        application.launchEnvironment["SPANREED_DEFAULTS_SUITE"] = defaultsSuite
    }

    override func tearDownWithError() throws {
        application.terminate()
        UserDefaults(suiteName: defaultsSuite)?.removePersistentDomain(forName: defaultsSuite)
        try? FileManager.default.removeItem(at: testFolder)
    }

    func testAppearanceChoicesApplyToAllNotesAndPersistAcrossRelaunch() throws {
        let original = "\u{FEFF}# Keep my Config\r\nfont-size = 20\r\nappearance\t= system  \r\nselected-fonts = SF Mono\r\nactive-font = SF Mono\r\ncurrent-text-size = 20\r\n"
        try writeConfig(original)
        application.launch()
        let home = application.windows["home"]
        XCTAssertTrue(home.textViews["note-editor"].waitForExistence(timeout: 5))
        let systemBrightness = try backgroundBrightness(of: home)
        application.typeKey("n", modifierFlags: .command)
        let untitled = application.windows["Untitled"]
        XCTAssertTrue(untitled.textViews["note-editor"].waitForExistence(timeout: 5))

        for choice in ["Dark", "Light", "System"] {
            chooseAppearance(choice)
            let expected = original.replacingOccurrences(of: "system  ", with: choice.lowercased() + "  ")
            XCTAssertEqual(try Data(contentsOf: configURL), Data(expected.utf8))
            let brightness = choice == "Dark" ? 0.1 : choice == "Light" ? 1.0 : systemBrightness
            assertBackground(of: untitled, near: brightness)
            application.typeKey("1", modifierFlags: .command)
            assertBackground(of: home, near: brightness)
            let attachment = XCTAttachment(screenshot: home.screenshot())
            attachment.name = "\(choice) appearance with title icon hidden"
            attachment.lifetime = .keepAlways
            add(attachment)

            application.typeKey("q", modifierFlags: .command)
            XCTAssertTrue(application.wait(for: .notRunning, timeout: 5))
            application.launch()
            XCTAssertTrue(home.textViews["note-editor"].waitForExistence(timeout: 5))
            assertBackground(of: home, near: brightness)
            XCTAssertEqual(try Data(contentsOf: configURL), Data(expected.utf8))
            application.typeKey("n", modifierFlags: .command)
            XCTAssertTrue(untitled.textViews["note-editor"].waitForExistence(timeout: 5))
            assertBackground(of: untitled, near: brightness)
        }
    }

    func testAppearanceChoicePreservesUnsavedConfigEditsAndUndo() throws {
        let original = "# My Config\nfont-size = 20\nappearance = system\nselected-fonts = SF Mono\nactive-font = SF Mono\ncurrent-text-size = 20\n"
        let saved = "# My Config\nfont-size = 20\nappearance = dark\nselected-fonts = SF Mono\nactive-font = SF Mono\ncurrent-text-size = 20\n"
        let comment = "# An unfinished Config edit\n"
        try writeConfig(original)
        application.launch()
        XCTAssertTrue(application.windows["home"].textViews["note-editor"].waitForExistence(timeout: 5))
        application.typeKey(",", modifierFlags: .command)
        let config = application.windows["Config"]
        let editor = config.textViews["note-editor"]
        XCTAssertTrue(editor.waitForExistence(timeout: 5))
        application.typeKey(.downArrow, modifierFlags: .command)
        application.pasteText(comment)
        chooseAppearance("Dark")
        XCTAssertEqual(try Data(contentsOf: configURL), Data(saved.utf8))
        XCTAssertEqual(editor.value as? String, saved + comment)
        application.typeKey("z", modifierFlags: .command)
        XCTAssertEqual(editor.value as? String, original + comment)
        application.typeKey("z", modifierFlags: [.command, .shift])
        XCTAssertEqual(editor.value as? String, saved + comment)
        application.typeKey("w", modifierFlags: .command)
        XCTAssertTrue(config.sheets.buttons["Save"].waitForExistence(timeout: 5))
        application.typeKey(.escape, modifierFlags: [])
        application.typeKey("s", modifierFlags: .command)
        XCTAssertEqual(try Data(contentsOf: configURL), Data((saved + comment).utf8))
    }

    func testSavingAppearanceInConfigAppliesItAndMenuChoicePersistsSystem() throws {
        application.launch()
        let home = application.windows["home"]
        XCTAssertTrue(home.textViews["note-editor"].waitForExistence(timeout: 5))
        chooseAppearance("Dark")
        XCTAssertTrue(try String(contentsOf: configURL, encoding: .utf8).contains("appearance = dark"))
        assertBackground(of: home, near: 0.1)
        application.typeKey(",", modifierFlags: .command)
        let editor = application.windows["Config"].textViews["note-editor"]
        XCTAssertTrue(editor.waitForExistence(timeout: 5))
        application.typeKey("a", modifierFlags: .command)
        application.pasteText("appearance = light\n")
        application.typeKey("s", modifierFlags: .command)
        application.typeKey("1", modifierFlags: .command)
        assertBackground(of: home, near: 1.0)
        application.typeKey(",", modifierFlags: .command)
        chooseAppearance("System")
        let expected = "appearance = system\nselected-fonts = SF Mono\nactive-font = SF Mono\nfont-size = 20\ncurrent-text-size = 20.0\n"
        XCTAssertEqual(editor.value as? String, expected)
        XCTAssertEqual(try String(contentsOf: configURL, encoding: .utf8), expected)
        application.typeKey("w", modifierFlags: .command)
        XCTAssertFalse(application.windows["Config"].exists)
    }

    private func chooseAppearance(_ choice: String) {
        let view = application.menuBars.menuBarItems["View"]
        view.click()
        view.menuItems["Appearance"].hover()
        let item = view.menuItems[choice]
        XCTAssertTrue(item.waitForExistence(timeout: 5), application.debugDescription)
        item.click()
    }

    private func backgroundBrightness(of window: XCUIElement) throws -> Double {
        let data = try XCTUnwrap(window.screenshot().image.tiffRepresentation)
        let bitmap = try XCTUnwrap(NSBitmapImageRep(data: data))
        let color = try XCTUnwrap(bitmap.colorAt(x: bitmap.pixelsWide / 2, y: bitmap.pixelsHigh / 2)?.usingColorSpace(.deviceRGB))
        return Double((color.redComponent + color.greenComponent + color.blueComponent) / 3)
    }

    private func assertBackground(of window: XCUIElement, near brightness: Double,
                                  file: StaticString = #filePath, line: UInt = #line) {
        let rendered = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
            guard let actual = try? self.backgroundBrightness(of: window) else { return false }
            return abs(actual - brightness) < 0.15
        }, object: nil)
        XCTAssertEqual(XCTWaiter.wait(for: [rendered], timeout: 5), .completed,
                       "The Note background did not adopt the selected appearance.", file: file, line: line)
    }

    private func writeConfig(_ text: String) throws {
        try FileManager.default.createDirectory(at: configURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        try Data(text.utf8).write(to: configURL)
    }
}
