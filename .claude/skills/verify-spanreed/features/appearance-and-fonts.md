# Appearance and fonts

View → Appearance switches every Note between System, Light, and Dark, and Format → Font switches every Note to another of the Selected Fonts. Each choice is written to the Config (`appearance`, `active-font`) and survives a relaunch.

## Sub-features

- `appearance-choose`: View → Appearance → System, Light, or Dark checks that item, recolors every window, and writes `appearance = system|light|dark`.
- `appearance-launch`: a Config with `appearance = dark` opens dark.
- `font-choose`: Format → Font → a family checks it, redraws every Note in that font, writes `active-font = <family>`, and keeps `current-text-size`.
- `font-context-menu`: right-clicking the editor shows the same Font submenu.
- `font-unavailable`: a Selected Font that is not installed appears disabled.

## How to get to it (user POV)

- View → Appearance → System, Light, Dark.
- Format → Font → a family from `selected-fonts`.
- Right-click in a Note → Font → a family.
- Edit `appearance` or `active-font` in the Config and save.

## Driving it with spanreed-verify

Preconditions:

- A fresh run; `doctor` passes.
- For `appearance-launch`: a seed Config with `appearance = dark`, launched with `--config`.
- For `font-unavailable`: a seed Config whose `selected-fonts` includes `Not A Real Font`.

- **Dark.** Open View → Appearance → Dark through the menu bar, then `waitForFile(configFile, t => t.includes("appearance = dark"))` and `snap("01-dark")`. The screenshot shows a dark editor.
- **Light and System.** Choose Light, then System, the same way. The Config reads `appearance = light`, then `appearance = system`; snap each.
- **Launch dark.** Launch the dark seed and snap. The first screenshot is already dark.
- **Font.** Open Format → Font → `Menlo`. `waitForFile(configFile, t => t.includes("active-font = Menlo"))` passes, `current-text-size` is unchanged, and the snap shows Menlo.
- **Context menu.** `await act("right-click editor", () => app.click(indexOf(await state(), /ID: note-editor/), { mouseButton: "right" }))`, then `waitFor(/Font/)`. Choosing a family there writes `active-font` the same way.
- **Unavailable.** Launch the `Not A Real Font` seed. A `Config errors` alert lists `Selected Font 'Not A Real Font' is not installed.`; after dismissing it, the Font menu shows that family disabled.

## Gotchas

- None of these menu items has a keyboard shortcut. The state lists `View` and `Format` under `menu bar`; opening their submenus by click is not yet driven. If a submenu never appears, use the right-click menu for fonts and report `appearance-choose` unreached; editing the Config does not count as the menu path.
- The Font submenu is rebuilt from the Config each time it opens, so a just-saved `selected-fonts` edit shows up without a relaunch.
- Appearance System follows the Mac's own setting; a System snap looks light or dark depending on the user's Mac.
- `Menlo` is part of macOS; other families in `selected-fonts` vary by Mac.
