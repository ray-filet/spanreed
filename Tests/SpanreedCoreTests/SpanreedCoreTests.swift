import XCTest
import SpanreedCore

final class SpanreedCoreTests: XCTestCase {
    private let installedFonts: Set<String> = ["SF Mono", "Menlo", "Arial"]

    func testActiveFontRewritePreservesEveryByteOutsideTheValue() {
        let text = "\u{FEFF}  active-font\t = \tSF Mono  \r\n# Café 日本\r\n\r\nfont-size=20.0\nselected-fonts = SF Mono, Menlo\r\n"
        let expected = "\u{FEFF}  active-font\t = \tMenlo  \r\n# Café 日本\r\n\r\nfont-size=20.0\nselected-fonts = SF Mono, Menlo\r\n"
        XCTAssertEqual(Data(Config.rewriteActiveFont(text, fontName: "Menlo").utf8), Data(expected.utf8))
    }

    func testMissingActiveFontIsAppendedWithTheExistingLineEnding() {
        let examples = [
            ("", "active-font = Menlo\n"),
            ("\u{FEFF}", "\u{FEFF}active-font = Menlo\n"),
            ("# My Config\nfont-size = 20", "# My Config\nfont-size = 20\nactive-font = Menlo\n"),
            ("# My Config\r\nfont-size = 20\r\n", "# My Config\r\nfont-size = 20\r\nactive-font = Menlo\r\n"),
            ("font-size = 20\r", "font-size = 20\ractive-font = Menlo\r")
        ]
        for (original, expected) in examples {
            XCTAssertEqual(Data(Config.rewriteActiveFont(original, fontName: "Menlo").utf8), Data(expected.utf8))
        }
    }

    func testActiveFontRewriteUpdatesTheLastValidDuplicate() {
        let original = "# active-font = comment\nactive-font = Arial\nactive-font = SF Mono\nactive-font = broken=value\nfont-size = 20\n"
        let expected = "# active-font = comment\nactive-font = Arial\nactive-font = Menlo\nactive-font = broken=value\nfont-size = 20\n"
        let rewritten = Config.rewriteActiveFont(original, fontName: "Menlo")
        XCTAssertEqual(rewritten, expected)
        XCTAssertEqual(Config.parse(rewritten, installedFontNames: installedFonts).activeFont, "Menlo")
    }

    func testActiveFontRewriteRepairsAnInvalidValueWithoutAddingAKey() {
        let original = "active-font = broken=value\nactive-font\t=   \nselected-fonts = SF Mono, Menlo\n"
        let expected = "active-font = broken=value\nactive-font\t=   Menlo\nselected-fonts = SF Mono, Menlo\n"
        let rewritten = Config.rewriteActiveFont(original, fontName: "Menlo")
        XCTAssertEqual(rewritten, expected)
        XCTAssertEqual(Config.parse(rewritten, installedFontNames: installedFonts).activeFont, "Menlo")
    }

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
