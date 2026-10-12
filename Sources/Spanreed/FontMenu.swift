import AppKit

@MainActor
final class FontMenu: NSObject, NSMenuDelegate {
    static let shared = FontMenu()

    func makeMenu() -> NSMenu {
        let menu = NSMenu(title: "Font")
        menu.autoenablesItems = false
        menu.delegate = self
        menuNeedsUpdate(menu)
        return menu
    }

    func menuNeedsUpdate(_ menu: NSMenu) {
        menu.removeAllItems()
        let settings = Configuration.shared.snapshot
        for font in settings.selectedFonts {
            let item = menu.addItem(withTitle: font, action: #selector(chooseFont(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = font
            item.state = font == settings.activeFont ? .on : .off
            item.isEnabled = !settings.unavailableFonts.contains(font)
        }
    }

    @objc private func chooseFont(_ sender: NSMenuItem) {
        guard let font = sender.representedObject as? String else { return }
        Configuration.shared.chooseFont(font)
    }
}
