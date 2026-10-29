# Config

The Config is a plain-text settings file at `config/config` inside the run (`~/.config/spanreed/config` for real users). Launch writes every missing setting with its default, Command-, opens it in a window titled `Config`, and saving that window applies the edits at once or lists errors in an alert.

## Sub-features

- `config-defaults`: launch writes `selected-fonts`, `active-font`, `font-size = 20`, `current-text-size = 20`, and `appearance = system`, with a comment above each, without opening a Config window.
- `config-preserve`: launch adds only missing settings; comments, explicit values, and line endings stay byte for byte.
- `config-open`: Command-, or Spanreed → Open Config… opens one `Config` window.
- `config-apply`: editing and saving with Command-S applies the change to every Note at once.
- `config-errors`: saving a bad line shows a `Config errors` alert listing `Line N: …`, and the rest of the Config still applies.

## How to get to it (user POV)

- Spanreed → Open Config…, or Command-,.
- Edit the file in any editor and relaunch Spanreed.

## Driving it with spanreed-verify

Preconditions:

- `config-defaults`: a fresh run with no `--config` seed.
- `config-preserve`: a seed such as `printf '# keep me\r\nfont-size = 24\r\n' > /tmp/spanreed-config`, launched with `--config /tmp/spanreed-config`.
- `doctor` passes.

- **Defaults.** After `launch`, run `spanreed-verify snap cfg-1 01-launched`. `01-launched.config` contains all five settings and `01-launched.ax.txt` shows only the `home` window.
- **Preserve.** Launch the seeded run and snap. The `.config` copy still starts with `# keep me\r\nfont-size = 24\r\n` (check with `od -c`), followed by the added settings.
- **Open.** `await act("Open Config", () => app.pressKey("cmd+comma")); await waitFor(/Config/)`, then `snap`. The `Config` window's text equals `configFile` on disk.
- **Apply.** In the Config window, `await act("move to end", () => app.pressKey("cmd+Down"))`, `await app.typeText("\nappearance = dark")`, `await act("Save", () => app.pressKey("cmd+s"))`, then `waitForFile(configFile, t => t.includes("appearance = dark"))` and `snap("02-dark")`. The screenshot shows a dark window. Restore with `appearance = system` and save again.
- **Errors.** Type a line `bogus line` and save. `await waitFor(/Config errors/)` shows the alert with `Line N: Expected key = value.`; `Return` dismisses it, and `configFile` contains the bad line as typed.

## Gotchas

- `selected-fonts` lists SF Mono and every installed monospaced family, so its value differs from Mac to Mac. Assert that the setting is present, not its value.
- For a repeated key the last line wins, which is why appending `appearance = dark` works. A bad line is skipped, and every other line still applies.
- The Config window counts as edited only when its text differs from the file, so typing and deleting the same character leaves it clean.
- An unknown key reports `Unknown key '<key>'.`; a font missing from the Mac reports `Selected Font '<name>' is not installed.`.
