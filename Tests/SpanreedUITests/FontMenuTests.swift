import AppKit
import XCTest

final class FontMenuTests: XCTestCase {
    private var application: XCUIApplication!
    private var testFolder: URL!
    private var defaultsSuite: String!
    private let noteText = String(repeating: "A readable note\n", count: 50)
    private var configURL: URL { testFolder.appendingPathComponent("Config/config") }

    override func setUpWithError() throws {
        continueAfterFailure = false
        testFolder = FileManager.default.temporaryDirectory.appendingPathComponent("SpanreedFontMenuTests-\(UUID().uuidString)")
        application = XCUIApplication()
        application.launchArguments = ["--home-note-folder", testFolder.appendingPathComponent("Home").path,
                                       "--config-folder", testFolder.appendingPathComponent("Config").path]
        defaultsSuite = "SpanreedFontMenuTests.\(UUID().uuidString)"
        application.launchEnvironment["SPANREED_DEFAULTS_SUITE"] = defaultsSuite
        try FileManager.default.createDirectory(at: testFolder.appendingPathComponent("Home"), withIntermediateDirectories: true)
        try noteText.write(to: testFolder.appendingPathComponent("Home/Home.txt"), atomically: true, encoding: .utf8)
    }

    override func tearDownWithError() throws {
        application.terminate()
        UserDefaults(suiteName: defaultsSuite)?.removePersistentDomain(forName: defaultsSuite)
        try? FileManager.default.removeItem(at: testFolder)
    }

    func testFormatFontChoiceRewritesOnlyTheActiveFontAndRetainsZoom() throws {
        let original = "\u{FEFF}# My Config\r\nselected-fonts = SF Mono, Menlo\r\n\r\nactive-font\t= SF Mono  \r\nfont-size = 20\r\ncurrent-text-size = 20\r\nappearance = system\r\n"
        let expected = "\u{FEFF}# My Config\r\nselected-fonts = SF Mono, Menlo\r\n\r\nactive-font\t= Menlo  \r\nfont-size = 20\r\ncurrent-text-size = 22.0\r\nappearance = system\r\n"
        try writeConfig(original)
        application.launch()
        let home = application.windows["home"].textViews["note-editor"]
        XCTAssertTrue(home.waitForExistence(timeout: 5))
        application.typeKey("=", modifierFlags: [.command, .shift])
        application.typeKey("=", modifierFlags: [.command, .shift])
        openFormatFontMenu()
        let format = application.menuBars.menuBarItems["Format"]
        XCTAssertEqual(format.menuItems.matching(identifier: "SF Mono").count, 1)
        XCTAssertEqual(format.menuItems.matching(identifier: "Menlo").count, 1)
        XCTAssertEqual(format.menuItems.count, 3, application.debugDescription)
        XCTAssertTrue(format.menuItems["SF Mono"].isEnabled)
        format.menuItems["Menlo"].click()
        XCTAssertEqual(try Data(contentsOf: configURL), Data(expected.utf8))
        XCTAssertEqual(home.value as? String, noteText)
        let zoomedHeight = home.frame.height
        application.typeKey("0", modifierFlags: .command)
        XCTAssertLessThan(home.frame.height, zoomedHeight)
    }

    func testContextualFontChoiceUpdatesOpenConfigAndPreservesUnsavedEdits() throws {
        let original = "selected-fonts = SF Mono, Menlo\nactive-font = SF Mono\nfont-size = 20\ncurrent-text-size = 20\nappearance = system\n"
        let savedText = "selected-fonts = SF Mono, Menlo\nactive-font = Menlo\nfont-size = 20\ncurrent-text-size = 20\nappearance = system\n"
        let unsavedComment = "# My unfinished Config edit\n"
        try writeConfig(original)
        application.launch()
        let home = application.windows["home"].textViews["note-editor"]
        XCTAssertTrue(home.waitForExistence(timeout: 5))
        application.typeKey(",", modifierFlags: .command)
        let config = application.windows["Config"]
        let editor = config.textViews["note-editor"]
        XCTAssertTrue(editor.waitForExistence(timeout: 5))
        application.typeKey(.downArrow, modifierFlags: .command)
        application.pasteText(unsavedComment)
        application.typeKey("1", modifierFlags: .command)
        home.rightClick()
        let font = home.menuItems["Font"]
        XCTAssertTrue(font.waitForExistence(timeout: 5), application.debugDescription)
        font.hover()
        XCTAssertTrue(home.menuItems["SF Mono"].waitForExistence(timeout: 5), application.debugDescription)
        home.menuItems["Menlo"].click()
        XCTAssertEqual(try Data(contentsOf: configURL), Data(savedText.utf8))
        XCTAssertEqual(editor.value as? String, savedText + unsavedComment)
        application.typeKey(",", modifierFlags: .command)
        application.typeKey("w", modifierFlags: .command)
        XCTAssertTrue(config.sheets.buttons["Save"].waitForExistence(timeout: 5))
        application.typeKey(.escape, modifierFlags: [])
        editor.click()
        application.typeKey("s", modifierFlags: .command)
        assertConfigBytes(Data((savedText + unsavedComment).utf8))
        application.typeKey("w", modifierFlags: .command)
        XCTAssertFalse(config.exists)
    }

    func testFontRewriteAndEarlierEditsCanBeUndoneAndRedoneWithoutLosingTheSavePrompt() throws {
        let original = "selected-fonts = SF Mono, Menlo\nactive-font = SF Mono\nfont-size = 20\ncurrent-text-size = 20\nappearance = system\n"
        let savedText = "selected-fonts = SF Mono, Menlo\nactive-font = Menlo\nfont-size = 20\ncurrent-text-size = 20\nappearance = system\n"
        let comment = "# An unsaved comment\n"
        try writeConfig(original)
        application.launch()
        XCTAssertTrue(application.windows["home"].textViews["note-editor"].waitForExistence(timeout: 5))
        application.typeKey(",", modifierFlags: .command)
        let config = application.windows["Config"]
        let editor = config.textViews["note-editor"]
        XCTAssertTrue(editor.waitForExistence(timeout: 5))
        application.typeKey(.downArrow, modifierFlags: .command)
        application.pasteText(comment)
        openFormatFontMenu()
        application.menuBars.menuBarItems["Format"].menuItems["Menlo"].click()
        XCTAssertEqual(editor.value as? String, savedText + comment)
        application.typeKey("z", modifierFlags: .command)
        XCTAssertEqual(editor.value as? String, original + comment)
        application.typeKey("z", modifierFlags: .command)
        XCTAssertEqual(editor.value as? String, original)
        XCTAssertEqual(try Data(contentsOf: configURL), Data(savedText.utf8))
        application.typeKey("w", modifierFlags: .command)
        XCTAssertTrue(config.sheets.buttons["Save"].waitForExistence(timeout: 5))
        application.typeKey(.escape, modifierFlags: [])
        editor.click()
        application.typeKey("z", modifierFlags: [.command, .shift])
        XCTAssertEqual(editor.value as? String, original + comment)
        application.typeKey("z", modifierFlags: [.command, .shift])
        XCTAssertEqual(editor.value as? String, savedText + comment)
        XCTAssertEqual(try Data(contentsOf: configURL), Data(savedText.utf8))
    }

    func testCanonicallyEquivalentUnsavedConfigBytesStillRequireSavingAfterAFontChoice() throws {
        let original = "# Café\nselected-fonts = SF Mono, Menlo\nactive-font = SF Mono\nfont-size = 20\ncurrent-text-size = 20\nappearance = system\n"
        let unsavedText = "# Cafe\u{0301}\nselected-fonts = SF Mono, Menlo\nactive-font = SF Mono\nfont-size = 20\ncurrent-text-size = 20\nappearance = system\n"
        try writeConfig(original)
        application.launch()
        XCTAssertTrue(application.windows["home"].textViews["note-editor"].waitForExistence(timeout: 5))
        application.typeKey(",", modifierFlags: .command)
        let config = application.windows["Config"]
        let editor = config.textViews["note-editor"]
        XCTAssertTrue(editor.waitForExistence(timeout: 5))
        application.typeKey("a", modifierFlags: .command)
        application.pasteText(unsavedText)
        openFormatFontMenu()
        application.menuBars.menuBarItems["Format"].menuItems["SF Mono"].click()
        XCTAssertEqual(Data((editor.value as? String ?? "").utf8), Data(unsavedText.utf8))
        XCTAssertEqual(try Data(contentsOf: configURL), Data(original.utf8))
        application.typeKey("w", modifierFlags: .command)
        XCTAssertTrue(config.sheets.buttons["Save"].waitForExistence(timeout: 5))
        application.typeKey(.escape, modifierFlags: [])
        editor.click()
        application.typeKey("s", modifierFlags: .command)
        assertConfigBytes(Data(unsavedText.utf8))
        application.typeKey("w", modifierFlags: .command)
        XCTAssertFalse(config.exists)
    }

    func testBothFontMenusShowOnlySelectedFontsAndDisableTheUnavailableActiveFont() throws {
        let original = "selected-fonts = SF Mono, Missing Spanreed Test Font, Menlo\nactive-font = Missing Spanreed Test Font\nfont-size = 20\ncurrent-text-size = 20\nappearance = system\n"
        try writeConfig(original)
        application.launch()
        XCTAssertTrue(application.dialogs.firstMatch.waitForExistence(timeout: 5))
        application.typeKey(.return, modifierFlags: [])
        let home = application.windows["home"].textViews["note-editor"]
        XCTAssertTrue(home.waitForExistence(timeout: 5))
        openFormatFontMenu()
        let format = application.menuBars.menuBarItems["Format"]
        XCTAssertEqual(format.menuItems.count, 4, application.debugDescription)
        XCTAssertTrue(format.menuItems["SF Mono"].isEnabled)
        XCTAssertTrue(format.menuItems["Menlo"].isEnabled)
        XCTAssertFalse(format.menuItems["Missing Spanreed Test Font"].isEnabled)
        attachScreenshot("Format menu checks the unavailable Active Font")
        application.typeKey(.escape, modifierFlags: [])
        home.rightClick()
        let font = home.menuItems["Font"]
        XCTAssertTrue(font.waitForExistence(timeout: 5))
        font.hover()
        XCTAssertEqual(font.menuItems.count, 3, application.debugDescription)
        XCTAssertTrue(font.menuItems["SF Mono"].isEnabled)
        XCTAssertTrue(font.menuItems["Menlo"].isEnabled)
        XCTAssertFalse(font.menuItems["Missing Spanreed Test Font"].isEnabled)
        attachScreenshot("Contextual menu matches the Selected Fonts and check mark")
        XCTAssertEqual(try Data(contentsOf: configURL), Data(original.utf8))
    }

    func testFontChoicesPersistSettingsAndFillMissingActiveFont() throws {
        application.launch()
        XCTAssertTrue(application.windows["home"].textViews["note-editor"].waitForExistence(timeout: 5))
        openFormatFontMenu()
        let format = application.menuBars.menuBarItems["Format"]
        let defaultFonts = Self.defaultFontsValue.components(separatedBy: ", ")
        XCTAssertEqual(format.menuItems.count, defaultFonts.count + 1, application.debugDescription)
        for font in defaultFonts {
            XCTAssertTrue(format.menuItems[font].isEnabled, font)
        }
        for font in ["SF Mono", "Menlo", "Monaco", "Courier New", "Andale Mono"] {
            XCTAssertTrue(defaultFonts.contains(font), font)
        }
        format.menuItems["SF Mono"].click()
        XCTAssertTrue(try String(contentsOf: configURL, encoding: .utf8)
            .contains("selected-fonts = \(Self.defaultFontsValue)\n"))
        application.typeKey(",", modifierFlags: .command)
        let config = application.windows["Config"]
        let editor = config.textViews["note-editor"]
        XCTAssertTrue(editor.waitForExistence(timeout: 5))
        let text = "# Keep the Active Font at the end\nselected-fonts = SF Mono, Menlo\nfont-size = 20\n"
        application.typeKey("a", modifierFlags: .command)
        application.pasteText(text)
        application.typeKey("s", modifierFlags: .command)
        let completed = text + "active-font = SF Mono\ncurrent-text-size = 20.0\nappearance = system\n"
        assertConfigBytes(Data(completed.utf8))
        XCTAssertEqual(editor.value as? String, completed)
        openFormatFontMenu()
        XCTAssertEqual(format.menuItems.count, 3)
        format.menuItems["Menlo"].click()
        let expected = completed.replacingOccurrences(of: "active-font = SF Mono", with: "active-font = Menlo")
        XCTAssertEqual(try Data(contentsOf: configURL), Data(expected.utf8))
        XCTAssertEqual(editor.value as? String, expected)
        application.typeKey("w", modifierFlags: .command)
        XCTAssertFalse(config.exists)
    }

    private func openFormatFontMenu() {
        let format = application.menuBars.menuBarItems["Format"]
        XCTAssertTrue(format.waitForExistence(timeout: 5), application.debugDescription)
        format.click()
        format.menuItems["Font"].hover()
    }

    private func attachScreenshot(_ name: String) {
        let attachment = XCTAttachment(screenshot: application.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    private func writeConfig(_ text: String) throws {
        try FileManager.default.createDirectory(at: configURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        try Data(text.utf8).write(to: configURL)
    }

    private func assertConfigBytes(_ expected: Data, file: StaticString = #filePath, line: UInt = #line) {
        let saved = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
            (try? Data(contentsOf: self.configURL)) == expected
        }, object: nil)
        let result = XCTWaiter.wait(for: [saved], timeout: 5)
        XCTAssertEqual(result, .completed, application.debugDescription, file: file, line: line)
    }
}
