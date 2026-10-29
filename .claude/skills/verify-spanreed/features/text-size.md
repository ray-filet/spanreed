# Text size

One text size applies to every open Note. Command-+ and Command-− change it by one point, Command-0 returns to the Config's `font-size`, and each change is saved to the Config as `current-text-size` and restored on the next launch.

## Sub-features

- `size-increase`: Command-+ or View → Increase Text Size grows every Note by 1 pt and writes `current-text-size = 21.0`.
- `size-decrease`: Command-− or View → Decrease Text Size shrinks every Note by 1 pt, never below 1.
- `size-reset`: Command-0 or View → Reset Text Size returns to `font-size`, leaving `font-size` unchanged.
- `size-all-windows`: the Home Note, Untitled Notes, and Config all show the same size.
- `size-persist`: a relaunch shows the last `current-text-size`.

## How to get to it (user POV)

- View → Increase Text Size, Decrease Text Size, Reset Text Size.
- Command-+ (Command-= also works), Command-−, Command-0.
- Edit `font-size` or `current-text-size` in the Config and save.

## Driving it with spanreed-verify

Preconditions:

- A fresh run seeded with several lines so size changes show: `printf 'A readable note\n%.0s' {1..50} > /tmp/spanreed-lines.txt`, then `spanreed-verify launch size-1 --home-text /tmp/spanreed-lines.txt`.
- `doctor` passes; `config` contains `font-size = 20` and `current-text-size = 20`.

- **Baseline.** `await snap("01-default")`. The screenshot shows SF Mono at 20 pt.
- **Increase.** `await act("Command-+", () => app.pressKey("cmd+equal")); await waitForFile(configFile, t => t.includes("current-text-size = 21.0"))`, then `await snap("02-increased")`. The text in `02-increased.png` is visibly larger than in `01-default.png`.
- **Every window.** `await act("New", () => app.pressKey("cmd+n"))`, type a line, `await snap("03-untitled")`. The Untitled Note shows the same size as the Home Note in `02-increased.png`.
- **Decrease.** `await act("Command-−", () => app.pressKey("cmd+minus")); await waitForFile(configFile, t => t.includes("current-text-size = 20.0"))`.
- **Reset.** Increase twice, then `await act("Command-0", () => app.pressKey("cmd+0")); await waitForFile(configFile, t => t.includes("current-text-size = 20.0") && t.includes("font-size = 20\n"))`.
- **Persist.** Increase once, quit with `cmd+q` and `waitForExit()`, close nothing else, run `spanreed-verify relaunch size-1` and `spanreed-verify snap size-1 04-relaunched`. `04-relaunched.config` has `current-text-size = 21.0` and the screenshot matches `02-increased.png`'s size.
- **Menu entry.** Repeat Increase through View → Increase Text Size in the menu bar. The Config changes the same way.

## Gotchas

- Launch writes `current-text-size = 20`; the zoom commands write `21.0` with a decimal. Match the exact form.
- Quitting with an Untitled Note open shows a save sheet; close it with `Don't Save` before `waitForExit()`.
- With the Config window open, a zoom rewrites its text in place and keeps the user's other unsaved Config edits unsaved.
- The key name for Command-+ is unconfirmed under `ocu`; if `cmd+equal` does nothing, try `cmd+plus` and record which one works here.
