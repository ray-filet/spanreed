import AppKit
import XCTest

final class ConfigTests: XCTestCase {
    private var application: XCUIApplication!
    private var testFolder: URL!
    private var defaultsSuite: String!
    private let noteText = String(repeating: "A readable note\n", count: 50)
    private var configURL: URL { testFolder.appendingPathComponent("Config/config") }

    override func setUpWithError() throws {
        continueAfterFailure = false
        testFolder = FileManager.default.temporaryDirectory.appendingPathComponent("SpanreedConfigTests-\(UUID().uuidString)")
        application = XCUIApplication()
        application.launchArguments = ["--home-note-folder", testFolder.appendingPathComponent("Home").path,
                                       "--config-folder", testFolder.appendingPathComponent("Config").path]
        defaultsSuite = "SpanreedConfigTests.\(UUID().uuidString)"
        application.launchEnvironment["SPANREED_DEFAULTS_SUITE"] = defaultsSuite
        try FileManager.default.createDirectory(at: testFolder.appendingPathComponent("Home"), withIntermediateDirectories: true)
        try noteText.write(to: testFolder.appendingPathComponent("Home/Home.txt"), atomically: true, encoding: .utf8)
    }

    override func tearDownWithError() throws {
        application.terminate()
        UserDefaults(suiteName: defaultsSuite)?.removePersistentDomain(forName: defaultsSuite)
        try? FileManager.default.removeItem(at: testFolder)
    }

    func testLaunchPersistsEveryDefaultWithoutOpeningConfig() throws {
        application.launch()
        XCTAssertTrue(application.windows["home"].textViews["note-editor"].waitForExistence(timeout: 5))
        XCTAssertFalse(application.windows["Config"].exists)
        let original = try Data(contentsOf: configURL)
        let text = String(decoding: original, as: UTF8.self)
        for setting in ["selected-fonts = SF Mono", "active-font = SF Mono", "font-size = 20",
                        "current-text-size = 20", "appearance = system"] {
            XCTAssertTrue(text.contains(setting), text)
        }
        let modificationDate = try configURL.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate
        application.typeKey("q", modifierFlags: .command)
        XCTAssertTrue(application.wait(for: .notRunning, timeout: 5))
        application.launch()
        XCTAssertTrue(application.windows["home"].textViews["note-editor"].waitForExistence(timeout: 5))
        XCTAssertEqual(try Data(contentsOf: configURL), original)
        XCTAssertEqual(try configURL.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate, modificationDate)
    }

    func testLaunchMigratesLegacyZoomButExplicitConfigSizeWins() throws {
        let defaults = try XCTUnwrap(UserDefaults(suiteName: defaultsSuite))
        defaults.set(31, forKey: "CurrentTextSize")
        application.launch()
        XCTAssertTrue(application.windows["home"].textViews["note-editor"].waitForExistence(timeout: 5))
        XCTAssertTrue(try String(contentsOf: configURL, encoding: .utf8).contains("current-text-size = 31.0"))
        XCTAssertNil(defaults.object(forKey: "CurrentTextSize"))
        application.typeKey("q", modifierFlags: .command)
        XCTAssertTrue(application.wait(for: .notRunning, timeout: 5))
        try writeConfig("font-size = 24\ncurrent-text-size = 28\n")
        defaults.set(40, forKey: "CurrentTextSize")
        application.launch()
        XCTAssertTrue(application.windows["home"].textViews["note-editor"].waitForExistence(timeout: 5))
        let text = try String(contentsOf: configURL, encoding: .utf8)
        XCTAssertTrue(text.hasPrefix("font-size = 24\ncurrent-text-size = 28\n"), text)
        XCTAssertNil(defaults.object(forKey: "CurrentTextSize"))
        application.typeKey("0", modifierFlags: .command)
        XCTAssertTrue(try String(contentsOf: configURL, encoding: .utf8).contains("current-text-size = 24.0"))
    }

    func testAppearanceChoiceRetriesFailedMigrationWithoutLosingLegacyZoom() throws {
        let defaults = try XCTUnwrap(UserDefaults(suiteName: defaultsSuite))
        defaults.set(31, forKey: "CurrentTextSize")
        let original = "font-size = 20\n"
        try writeConfig(original)
        let folder = configURL.deletingLastPathComponent()
        try FileManager.default.setAttributes([.posixPermissions: 0o555], ofItemAtPath: folder.path)
        defer { try? FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: folder.path) }
        application.launch()
        XCTAssertTrue(application.dialogs.firstMatch.waitForExistence(timeout: 5))
        XCTAssertEqual(try String(contentsOf: configURL, encoding: .utf8), original)
        XCTAssertEqual(defaults.double(forKey: "CurrentTextSize"), 31)
        application.typeKey(.return, modifierFlags: [])
        let home = application.windows["home"].textViews["note-editor"]
        XCTAssertTrue(home.waitForExistence(timeout: 5))
        let zoomHeight = home.frame.height
        application.typeKey(",", modifierFlags: .command)
        let editor = application.windows["Config"].textViews["note-editor"]
        XCTAssertTrue(editor.waitForExistence(timeout: 5))
        try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: folder.path)
        let view = application.menuBars.menuBarItems["View"]
        view.click()
        view.menuItems["Appearance"].hover()
        let dark = view.menuItems["Dark"]
        XCTAssertTrue(dark.waitForExistence(timeout: 5))
        dark.click()
        let saved = try String(contentsOf: configURL, encoding: .utf8)
        XCTAssertTrue(saved.contains("current-text-size = 31.0"), saved)
        XCTAssertTrue(saved.contains("appearance = dark"), saved)
        XCTAssertEqual(editor.value as? String, saved)
        XCTAssertEqual(home.frame.height, zoomHeight, accuracy: 1)
        XCTAssertNil(defaults.object(forKey: "CurrentTextSize"))
    }

    func testUnreadableConfigIsNotOverwrittenAndLegacyZoomIsNotDiscarded() throws {
        let defaults = try XCTUnwrap(UserDefaults(suiteName: defaultsSuite))
        defaults.set(31, forKey: "CurrentTextSize")
        try FileManager.default.createDirectory(at: configURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        let original = Data([0xFF, 0xFE, 0x00])
        try original.write(to: configURL)
        application.launch()
        XCTAssertTrue(application.dialogs.firstMatch.waitForExistence(timeout: 5))
        XCTAssertEqual(try Data(contentsOf: configURL), original)
        XCTAssertEqual(defaults.double(forKey: "CurrentTextSize"), 31)
        application.typeKey(.return, modifierFlags: [])
        XCTAssertTrue(application.windows["home"].textViews["note-editor"].exists)
    }

    func testCommandCommaOpensCommentedConfigAndReusesItsWindow() throws {
        application.launch()
        XCTAssertTrue(application.windows["home"].textViews["note-editor"].waitForExistence(timeout: 5))
        application.typeKey(",", modifierFlags: .command)
        let config = application.windows["Config"]
        let editor = config.textViews["note-editor"]
        XCTAssertTrue(editor.waitForExistence(timeout: 5))
        let diskText = try String(contentsOf: configURL, encoding: .utf8)
        XCTAssertEqual(editor.value as? String, diskText)
        XCTAssertTrue(diskText.contains("#"))
        XCTAssertTrue(diskText.contains("selected-fonts = SF Mono"))
        XCTAssertTrue(diskText.contains("active-font = SF Mono"))
        XCTAssertTrue(diskText.contains("font-size = 20"))
        XCTAssertTrue(diskText.contains("current-text-size = 20"))
        XCTAssertTrue(diskText.contains("appearance = system"))
        application.typeKey("1", modifierFlags: .command)
        application.typeKey(",", modifierFlags: .command)
        XCTAssertEqual(application.windows.count, 2)
        XCTAssertEqual(application.windows.matching(identifier: "Config").count, 1)
        application.typeKey(.downArrow, modifierFlags: .command)
        application.typeText("# An unsaved Config comment")
        XCTAssertEqual(try String(contentsOf: configURL, encoding: .utf8), diskText)
        application.typeKey("w", modifierFlags: .command)
        XCTAssertTrue(config.sheets.buttons["Save"].waitForExistence(timeout: 5))
        application.typeKey(.escape, modifierFlags: [])
        XCTAssertTrue(config.exists)
        XCTAssertEqual(try String(contentsOf: configURL, encoding: .utf8), diskText)
        application.typeKey("s", modifierFlags: .command)
        application.typeKey("w", modifierFlags: .command)
        XCTAssertFalse(config.exists)
    }

    func testSavingConfigAppliesFontSizeToEveryNoteAndResetUsesIt() throws {
        application.launch()
        let home = application.windows["home"].textViews["note-editor"]
        XCTAssertTrue(home.waitForExistence(timeout: 5))
        let defaultHeight = home.frame.height
        application.typeKey(",", modifierFlags: .command)
        let editor = application.windows["Config"].textViews["note-editor"]
        XCTAssertTrue(editor.waitForExistence(timeout: 5))
        let originalConfig = try String(contentsOf: configURL, encoding: .utf8)
        application.typeKey("a", modifierFlags: .command)
        let newConfig = "selected-fonts = SF Mono, Menlo\nactive-font = Menlo\nfont-size = 32\n"
        application.pasteText(newConfig)
        XCTAssertEqual(home.frame.height, defaultHeight, accuracy: 1)
        XCTAssertEqual(try String(contentsOf: configURL, encoding: .utf8), originalConfig)
        application.typeKey("s", modifierFlags: .command)
        let savedConfig = newConfig + "current-text-size = 32.0\nappearance = system\n"
        XCTAssertEqual(try String(contentsOf: configURL, encoding: .utf8), savedConfig)
        XCTAssertEqual(editor.value as? String, savedConfig)
        XCTAssertGreaterThan(home.frame.height, defaultHeight * 1.4)
        let configuredHeight = home.frame.height
        application.typeKey("=", modifierFlags: [.command, .shift])
        XCTAssertGreaterThan(home.frame.height, configuredHeight)
        application.typeKey("0", modifierFlags: .command)
        XCTAssertEqual(home.frame.height, configuredHeight, accuracy: 1)
        application.typeKey("n", modifierFlags: .command)
        let untitled = application.windows["Untitled"].textViews["note-editor"]
        XCTAssertTrue(untitled.waitForExistence(timeout: 5))
        application.pasteText(noteText)
        XCTAssertEqual(untitled.frame.height, configuredHeight, accuracy: 1)
        let screenshot = XCTAttachment(screenshot: application.screenshot())
        screenshot.name = "Config applies Menlo at 32 points to all notes"
        screenshot.lifetime = .keepAlways
        add(screenshot)
    }

    func testSavingBadConfigShowsOneAlertListingEveryBadLine() throws {
        application.launch()
        XCTAssertTrue(application.windows["home"].textViews["note-editor"].waitForExistence(timeout: 5))
        application.typeKey(",", modifierFlags: .command)
        XCTAssertTrue(application.windows["Config"].textViews["note-editor"].waitForExistence(timeout: 5))
        application.typeKey("a", modifierFlags: .command)
        application.pasteText("font-size = invalid\nunknown = value\n")
        application.typeKey("s", modifierFlags: .command)
        let alert = application.dialogs.firstMatch
        XCTAssertTrue(alert.waitForExistence(timeout: 5))
        XCTAssertEqual(application.dialogs.count, 1)
        let message = alert.staticTexts.allElementsBoundByIndex.map { ($0.value as? String) ?? $0.label }.joined(separator: "\n")
        XCTAssertTrue(message.contains("Line 1"), message)
        XCTAssertTrue(message.contains("Line 2"), message)
        application.typeKey(.return, modifierFlags: [])
        XCTAssertFalse(application.dialogs.firstMatch.exists)
        XCTAssertTrue(application.windows["home"].exists)
        XCTAssertTrue(application.windows["Config"].exists)
    }

    func testBrokenConfigStillLaunchesHomeNoteWithDefaultsAndOneErrorAlert() throws {
        application.launch()
        let home = application.windows["home"].textViews["note-editor"]
        XCTAssertTrue(home.waitForExistence(timeout: 5))
        let defaultHeight = home.frame.height
        application.typeKey("q", modifierFlags: .command)
        XCTAssertTrue(application.wait(for: .notRunning, timeout: 5))
        try writeConfig("font-size = -5\nnot a setting\n")
        application.launch()
        let alert = application.dialogs.firstMatch
        XCTAssertTrue(alert.waitForExistence(timeout: 5))
        XCTAssertEqual(application.dialogs.count, 1)
        XCTAssertTrue(home.exists)
        XCTAssertEqual(home.value as? String, noteText)
        XCTAssertEqual(home.frame.height, defaultHeight, accuracy: 1)
        let message = alert.staticTexts.allElementsBoundByIndex.map { ($0.value as? String) ?? $0.label }.joined(separator: "\n")
        XCTAssertTrue(message.contains("Line 1"), message)
        XCTAssertTrue(message.contains("Line 2"), message)
        application.typeKey(.return, modifierFlags: [])
        XCTAssertFalse(application.dialogs.firstMatch.exists)
        application.typeKey(.downArrow, modifierFlags: .command)
        application.typeText("Still ready to type")
        XCTAssertTrue((home.value as? String)?.hasSuffix("Still ready to type") == true)
    }

    func testFileOpenAndRecentRecognizeConfigAndPreserveItsBOMAndCRLFOnSave() throws {
        let original = "\u{FEFF}# Keep this comment\r\nselected-fonts = SF Mono\r\nactive-font = SF Mono\r\nfont-size = 20\r\ncurrent-text-size = 20\r\nappearance = system\r\n"
        try writeConfig(original)
        application.launch()
        let home = application.windows["home"].textViews["note-editor"]
        XCTAssertTrue(home.waitForExistence(timeout: 5))
        let defaultHeight = home.frame.height
        application.typeKey("o", modifierFlags: .command)
        XCTAssertTrue(application.buttons["OKButton"].waitForExistence(timeout: 5))
        application.typeKey("g", modifierFlags: [.command, .shift])
        application.typeKey("a", modifierFlags: .command)
        application.typeText(configURL.path)
        application.typeKey(.return, modifierFlags: [])
        application.buttons["OKButton"].click()
        let config = application.windows["Config"]
        XCTAssertTrue(config.textViews["note-editor"].waitForExistence(timeout: 5), application.debugDescription)
        application.typeKey(",", modifierFlags: .command)
        XCTAssertEqual(application.windows.count, 2)
        application.typeKey(.downArrow, modifierFlags: .command)
        application.typeText("font-size = 32\ncurrent-text-size = 32\n")
        application.typeKey("s", modifierFlags: .command)
        XCTAssertEqual(try Data(contentsOf: configURL), Data((original + "font-size = 32\ncurrent-text-size = 32\n").utf8))
        XCTAssertGreaterThan(home.frame.height, defaultHeight * 1.4)
        application.typeKey("w", modifierFlags: .command)
        XCTAssertFalse(config.exists)
        application.menuBars.menuBarItems["File"].click()
        application.menuItems["Open Recent"].hover()
        let recentConfig = application.menuBars.menuBarItems["File"].menuItems["config"].firstMatch
        XCTAssertTrue(recentConfig.waitForExistence(timeout: 5))
        recentConfig.click()
        XCTAssertTrue(config.textViews["note-editor"].waitForExistence(timeout: 5), application.debugDescription)
        application.typeKey(",", modifierFlags: .command)
        XCTAssertEqual(application.windows.count, 2)
        application.typeKey(.downArrow, modifierFlags: .command)
        application.typeText("font-size = 24\ncurrent-text-size = 24\n")
        application.typeKey("s", modifierFlags: .command)
        XCTAssertGreaterThan(home.frame.height, defaultHeight)
        XCTAssertLessThan(home.frame.height, defaultHeight * 1.4)
    }

    func testLaunchLoadsConfigSizeAndPreservesZoomUntilResetToLatestDefault() throws {
        application.launch()
        let home = application.windows["home"].textViews["note-editor"]
        XCTAssertTrue(home.waitForExistence(timeout: 5))
        let defaultHeight = home.frame.height
        application.typeKey("q", modifierFlags: .command)
        XCTAssertTrue(application.wait(for: .notRunning, timeout: 5))
        try writeConfig("font-size = 32\n")
        application.launch()
        XCTAssertTrue(home.waitForExistence(timeout: 5))
        XCTAssertGreaterThan(home.frame.height, defaultHeight * 1.4)
        let configuredHeight = home.frame.height
        application.typeKey("=", modifierFlags: [.command, .shift])
        application.typeKey("=", modifierFlags: [.command, .shift])
        let zoomHeight = home.frame.height
        XCTAssertGreaterThan(zoomHeight, configuredHeight)
        application.typeKey("q", modifierFlags: .command)
        XCTAssertTrue(application.wait(for: .notRunning, timeout: 5))
        let zoomConfig = try String(contentsOf: configURL, encoding: .utf8)
        XCTAssertTrue(zoomConfig.contains("current-text-size = 34.0"), zoomConfig)
        try writeConfig(zoomConfig.replacingOccurrences(of: "font-size = 32\n", with: "font-size = 24\n"))
        application.launch()
        XCTAssertTrue(home.waitForExistence(timeout: 5))
        XCTAssertEqual(home.frame.height, zoomHeight, accuracy: 1)
        application.typeKey("0", modifierFlags: .command)
        XCTAssertGreaterThan(home.frame.height, defaultHeight)
        XCTAssertLessThan(home.frame.height, configuredHeight)
        XCTAssertEqual(try String(contentsOf: configURL, encoding: .utf8),
                       "font-size = 24\nselected-fonts = \(Self.defaultFontsValue)\nactive-font = SF Mono\ncurrent-text-size = 24.0\nappearance = system\n")
    }

    func testOpenTreatsExtensionlessAndUnfamiliarExtensionsAsUTF8Notes() throws {
        application.launch()
        XCTAssertTrue(application.windows["home"].textViews["note-editor"].waitForExistence(timeout: 5))
        for name in ["extensionless", "Plain note.unfamiliar-spanreed"] {
            let url = testFolder.appendingPathComponent(name)
            let text = "Café 日本 in a note named " + name
            try text.write(to: url, atomically: true, encoding: .utf8)
            application.typeKey("o", modifierFlags: .command)
            XCTAssertTrue(application.buttons["OKButton"].waitForExistence(timeout: 5))
            application.typeKey("g", modifierFlags: [.command, .shift])
            application.typeKey("a", modifierFlags: .command)
            application.typeText(url.path)
            application.typeKey(.return, modifierFlags: [])
            application.buttons["OKButton"].click()
            let note = application.windows[name]
            XCTAssertTrue(note.textViews["note-editor"].waitForExistence(timeout: 5), application.debugDescription)
            XCTAssertEqual(note.textViews["note-editor"].value as? String, text)
            application.typeKey("w", modifierFlags: .command)
            XCTAssertFalse(note.exists)
        }
    }

    func testConfigSaveAsCreatesAnOrdinaryNoteWithoutApplyingItsSettings() throws {
        application.launch()
        let home = application.windows["home"].textViews["note-editor"]
        XCTAssertTrue(home.waitForExistence(timeout: 5))
        let defaultHeight = home.frame.height
        application.typeKey(",", modifierFlags: .command)
        let config = application.windows["Config"]
        XCTAssertTrue(config.textViews["note-editor"].waitForExistence(timeout: 5))
        let originalConfig = try Data(contentsOf: configURL)
        application.typeKey("a", modifierFlags: .command)
        application.pasteText("font-size = 32\n")
        application.typeKey("s", modifierFlags: [.command, .shift])
        let savePanel = config.sheets.firstMatch
        XCTAssertTrue(savePanel.waitForExistence(timeout: 5))
        application.typeKey("g", modifierFlags: [.command, .shift])
        application.typeKey("a", modifierFlags: .command)
        application.typeText(testFolder.path)
        application.typeKey(.return, modifierFlags: [])
        let name = savePanel.textFields["saveAsNameTextField"]
        name.click()
        application.typeKey("a", modifierFlags: .command)
        name.typeText("Config copy.txt")
        savePanel.buttons["OKButton"].click()
        let copy = application.windows["Config copy.txt"]
        XCTAssertTrue(copy.textViews["note-editor"].waitForExistence(timeout: 5), application.debugDescription)
        XCTAssertEqual(try Data(contentsOf: configURL), originalConfig)
        XCTAssertEqual(home.frame.height, defaultHeight, accuracy: 1)
        application.typeKey(.downArrow, modifierFlags: .command)
        application.typeText("font-size = 40\n")
        application.typeKey("s", modifierFlags: .command)
        XCTAssertEqual(home.frame.height, defaultHeight, accuracy: 1)
        application.typeKey(",", modifierFlags: .command)
        XCTAssertTrue(application.windows["Config"].textViews["note-editor"].waitForExistence(timeout: 5))
        XCTAssertEqual(application.windows.count, 3)
    }

    private func writeConfig(_ text: String) throws {
        try FileManager.default.createDirectory(at: configURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        try Data(text.utf8).write(to: configURL)
    }
}
