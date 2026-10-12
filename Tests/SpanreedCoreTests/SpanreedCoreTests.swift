import XCTest
import SpanreedCore

final class SpanreedCoreTests: XCTestCase {
    private let installedFonts: Set<String> = ["SF Mono", "Menlo", "Arial"]

    func testEmptyConfigResolvesToDefaultsWithoutErrors() {
        let config = Config.parse("", installedFontNames: installedFonts)
        XCTAssertEqual(config.selectedFonts, ["SF Mono"])
        XCTAssertEqual(config.activeFont, "SF Mono")
        XCTAssertEqual(config.fontSize, 20)
        XCTAssertEqual(config.effectiveFont, "SF Mono")
        XCTAssertEqual(config.unavailableFonts, [])
        XCTAssertEqual(config.errors, [])
    }
    func testValidSettingsIgnoreCommentsAndBlankLines() {
        let text = """
          # My font choices

        selected-fonts = SF Mono, Menlo, Arial
        active-font = Menlo
        font-size = 32.5
        """
        let config = Config.parse(text, installedFontNames: installedFonts)
        XCTAssertEqual(config.selectedFonts, ["SF Mono", "Menlo", "Arial"])
        XCTAssertEqual(config.activeFont, "Menlo")
        XCTAssertEqual(config.effectiveFont, "Menlo")
        XCTAssertEqual(config.fontSize, 32.5)
        XCTAssertEqual(config.errors, [])
    }
    func testBadLinesReportTheirNumbersAndLeaveValidSettingsIntact() {
        let text = """
        font-size = 28
        selected-fonts = SF Mono, Menlo
        active-font = Menlo
        unknown = value
        font-size = nope
        font-size = 0
        font-size = -2
        font-size = inf
        font-size = nan
        not a setting
        active-font =
        selected-fonts = Menlo,,Arial
        """
        let config = Config.parse(text, installedFontNames: installedFonts)
        XCTAssertEqual(config.errors.map(\.lineNumber), [4, 5, 6, 7, 8, 9, 10, 11, 12])
        XCTAssertTrue(config.errors.allSatisfy { !$0.message.isEmpty })
        XCTAssertEqual(config.selectedFonts, ["SF Mono", "Menlo"])
        XCTAssertEqual(config.activeFont, "Menlo")
        XCTAssertEqual(config.fontSize, 28)
    }
    func testInvalidAndUnavailableFontsFallbackWithoutChangingSelections() {
        let outsideSelection = Config.parse("selected-fonts = SF Mono, Menlo\nactive-font = Arial", installedFontNames: installedFonts)
        XCTAssertEqual(outsideSelection.activeFont, "Arial")
        XCTAssertEqual(outsideSelection.effectiveFont, "SF Mono")
        XCTAssertEqual(outsideSelection.errors.map(\.lineNumber), [2])

        let unavailable = Config.parse("selected-fonts = SF Mono, Missing Font\nactive-font = Missing Font", installedFontNames: installedFonts)
        XCTAssertEqual(unavailable.selectedFonts, ["SF Mono", "Missing Font"])
        XCTAssertEqual(unavailable.activeFont, "Missing Font")
        XCTAssertEqual(unavailable.effectiveFont, "SF Mono")
        XCTAssertEqual(unavailable.unavailableFonts, ["Missing Font"])
        XCTAssertEqual(unavailable.errors.map(\.lineNumber), [1])

        let inactiveMissing = Config.parse("selected-fonts = SF Mono, Missing Font\nactive-font = SF Mono", installedFontNames: installedFonts)
        XCTAssertEqual(inactiveMissing.effectiveFont, "SF Mono")
        XCTAssertEqual(inactiveMissing.unavailableFonts, ["Missing Font"])
        XCTAssertEqual(inactiveMissing.errors.map(\.lineNumber), [1])

        let emptySelection = Config.parse("selected-fonts =  ", installedFontNames: installedFonts)
        XCTAssertEqual(emptySelection.selectedFonts, ["SF Mono"])
        XCTAssertEqual(emptySelection.errors, [])
    }
    func testBOMAndCRLFKeepSettingsAndErrorLineNumbers() {
        let config = Config.parse("\u{FEFF}selected-fonts = SF Mono, Menlo\r\n# A comment\r\n\r\nactive-font = Menlo\r\ninvalid\r\nfont-size = 24\r\n", installedFontNames: installedFonts)
        XCTAssertEqual(config.selectedFonts, ["SF Mono", "Menlo"])
        XCTAssertEqual(config.activeFont, "Menlo")
        XCTAssertEqual(config.fontSize, 24)
        XCTAssertEqual(config.errors.map(\.lineNumber), [5])
    }
    func testDefaultConfigDocumentsEveryKeyAndResolvesWithoutErrors() {
        let text = Config.defaultText
        let config = Config.parse(text, installedFontNames: installedFonts)
        XCTAssertEqual(config.selectedFonts, ["SF Mono"])
        XCTAssertEqual(config.activeFont, "SF Mono")
        XCTAssertEqual(config.fontSize, 20)
        XCTAssertEqual(config.errors, [])
        let lines = text.split(whereSeparator: { $0.isNewline })
        for key in ["selected-fonts", "active-font", "font-size"] {
            let index = lines.firstIndex { $0.hasPrefix(key + " =") }
            XCTAssertNotNil(index)
            if let index {
                XCTAssertGreaterThan(index, lines.startIndex)
                if index > lines.startIndex { XCTAssertTrue(lines[index - 1].hasPrefix("#")) }
            }
        }
    }
}
