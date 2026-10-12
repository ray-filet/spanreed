import AppKit
import XCTest

final class AppearanceMenuTests: XCTestCase {
    private var application: XCUIApplication!
    private var testFolder: URL!
    private var defaultsSuite: String!
    private var configURL: URL { testFolder.appendingPathComponent("Config/config") }

    override func setUpWithError() throws {
        continueAfterFailure = false
        testFolder = FileManager.default.temporaryDirectory.appendingPathComponent("SpanreedAppearanceTests-\(UUID().uuidString)")
        application = XCUIApplication()
        application.launchArguments = ["--home-note-folder", testFolder.appendingPathComponent("Home").path,
                                       "--config-folder", testFolder.appendingPathComponent("Config").path]
        defaultsSuite = "SpanreedAppearanceTests.\(UUID().uuidString)"
        application.launchEnvironment["SPANREED_DEFAULTS_SUITE"] = defaultsSuite
        try FileManager.default.createDirectory(at: testFolder.appendingPathComponent("Home"), withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        application.terminate()
        UserDefaults(suiteName: defaultsSuite)?.removePersistentDomain(forName: defaultsSuite)
        try? FileManager.default.removeItem(at: testFolder)
    }

    func testViewAppearanceMenuSwitchesModesAndSavesTheChoiceToConfig() throws {
        application.launch()
        let home = application.windows["home"].textViews["note-editor"]
        XCTAssertTrue(home.waitForExistence(timeout: 5))

        chooseAppearance("Dark")
        XCTAssertTrue(configContains("appearance = dark"))
        XCTAssertTrue(waitForBackground(isDark: true, of: home))

        chooseAppearance("Light")
        XCTAssertTrue(configContains("appearance = light"))
        XCTAssertTrue(waitForBackground(isDark: false, of: home))

        chooseAppearance("System")
        XCTAssertTrue(configContains("appearance = system"))
    }

    func testConfigAppearanceIsAppliedAtLaunch() throws {
        try FileManager.default.createDirectory(at: configURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        try Data("appearance = dark\n".utf8).write(to: configURL)
        application.launch()
        let home = application.windows["home"].textViews["note-editor"]
        XCTAssertTrue(home.waitForExistence(timeout: 5))
        XCTAssertTrue(waitForBackground(isDark: true, of: home))
    }

    private func chooseAppearance(_ title: String) {
        let view = application.menuBars.menuBarItems["View"]
        XCTAssertTrue(view.waitForExistence(timeout: 5), application.debugDescription)
        view.click()
        view.menuItems["Appearance"].hover()
        XCTAssertTrue(view.menuItems[title].waitForExistence(timeout: 5), application.debugDescription)
        view.menuItems[title].click()
    }

    private func configContains(_ line: String) -> Bool {
        let saved = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
            ((try? String(contentsOf: self.configURL, encoding: .utf8)) ?? "").contains(line)
        }, object: nil)
        return XCTWaiter.wait(for: [saved], timeout: 5) == .completed
    }

    private func waitForBackground(isDark: Bool, of element: XCUIElement) -> Bool {
        let matches = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
            self.isDark(element.screenshot().image) == isDark
        }, object: nil)
        return XCTWaiter.wait(for: [matches], timeout: 5) == .completed
    }

    /// Samples the empty editor background near a corner, away from any text.
    private func isDark(_ image: NSImage) -> Bool {
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else { return false }
        let bitmap = NSBitmapImageRep(cgImage: cgImage)
        let color = bitmap.colorAt(x: bitmap.pixelsWide - 20, y: bitmap.pixelsHigh - 20)?.usingColorSpace(.sRGB)
        return (color?.brightnessComponent ?? 1) < 0.5
    }
}
