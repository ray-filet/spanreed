import AppKit
import SpanreedCore

@MainActor
final class AppearanceMenu: NSObject, NSMenuDelegate {
    static let shared = AppearanceMenu()

    private static let titles: [Appearance: String] = [.system: "System", .light: "Light", .dark: "Dark"]

    func makeMenu() -> NSMenu {
        let menu = NSMenu(title: "Appearance")
        menu.autoenablesItems = false
        menu.delegate = self
        for appearance in [Appearance.system, .light, .dark] {
            let item = menu.addItem(withTitle: Self.titles[appearance]!, action: #selector(chooseAppearance(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = appearance.rawValue
        }
        menuNeedsUpdate(menu)
        return menu
    }

    func menuNeedsUpdate(_ menu: NSMenu) {
        let current = Configuration.shared.snapshot.appearance.rawValue
        for item in menu.items {
            item.state = item.representedObject as? String == current ? .on : .off
        }
    }

    @objc private func chooseAppearance(_ sender: NSMenuItem) {
        guard let raw = sender.representedObject as? String, let appearance = Appearance(rawValue: raw) else { return }
        Configuration.shared.chooseAppearance(appearance)
    }
}
