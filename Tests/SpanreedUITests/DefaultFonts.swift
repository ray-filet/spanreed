import AppKit
import XCTest

extension XCTestCase {
    /// The selected-fonts value Spanreed writes when it fills in an absent setting:
    /// SF Mono first, then every installed fixed-pitch family in alphabetical order.
    static var defaultFontsValue: String {
        let names = NSFontManager.shared.availableFontNames(with: .fixedPitchFontMask) ?? []
        let families = Set(names.compactMap { NSFont(name: $0, size: 12)?.familyName })
        return (["SF Mono"] + families.subtracting(["SF Mono"]).sorted()).joined(separator: ", ")
    }
}
