---
name: verify-spanreed
description: Launch and drive Spanreed, the macOS AppKit plain-text editor, in an isolated instance through ocu (Open Computer Use), and capture screenshot, accessibility, and file evidence. Use when proving a Spanreed change works in the real app, reproducing a Spanreed bug by hand, or screenshotting Spanreed.
---

# Verify Spanreed

Spanreed is a desktop app: the user touches Note windows, the menu bar, and two files on disk (the Home Note and the Config). Verification drives a private copy of the Debug build through `ocu` and proves each behavior twice: once on screen, once in the files it writes. Domain terms (Note, Home Note, Config, Active Font) are in `GLOSSARY.md`.

Every command goes through one helper, run from the repo root:

```sh
.claude/skills/verify-spanreed/bin/spanreed-verify <launch|doctor|drive|snap|relaunch|cleanup|list> ...
```

The rest of this file calls it `spanreed-verify`. Pick a run id (lowercase letters, digits, hyphens) per verification, such as `home-1`.

## Isolation

Each run is a sealed instance, so two runs side by side, or a run next to the user's own Spanreed, never share state:

- `.build/verify/runs/<id>/` holds the run's app copy, `home/Home.txt`, `config/config`, a `files/` folder for classic Notes, `pid`, `meta`, and `app.log`.
- The app copy is re-stamped with bundle id `com.rayfilet.Spanreed.verify.<id>` and ad-hoc re-signed. That id is how `ocu` tells this instance from any other Spanreed, and it keeps Open Recent and standard UserDefaults per run.
- `SPANREED_DEFAULTS_SUITE=com.rayfilet.Spanreed.verify.<id>.defaults` holds the window frame.

Drive only the bundle id your run printed. Any other Spanreed process (`doctor` lists them) belongs to the user: never quit, kill, or read it.

## Launch

```sh
spanreed-verify launch home-1
spanreed-verify launch cfg-1 --config /path/to/seed-config --home-text /path/to/seed-home.txt
```

`launch` rebuilds Debug into `.build/verify/DerivedData` (incremental, about 20 s cold), copies and stamps the app, and starts it with the run's folders. It is ready when it prints `READY run=<id> pid=<pid> bundle=<bundle>`: the process is alive, `Home.txt` and `config` exist, and a window titled `home` is on the window list. Start from an empty run unless a feature's preconditions ask for a seed. A run id that already exists is refused; `relaunch <id>` restarts a quit run on its existing state, without rebuilding, to prove what survives a relaunch.

Launch activates Spanreed and takes keyboard focus once. Tell the user before launching while they work on this Mac, since their typing lands in the run's Home Note until they click away.

Teardown is `spanreed-verify cleanup <id>` (see Cleanup).

## Doctor

```sh
spanreed-verify doctor home-1
```

Run it first, and again whenever an action does nothing. It is read-only and exits 0 only when the instance is worth driving: the pid is this run's app copy with the run's folders, the bundle id matches, the screen is unlocked, `ocu` has Accessibility and Screen Recording, and `ocu snapshot` can read the instance. It also notes a stale build (DerivedData is newer than the run, so launch a new run) and a missing on-screen `home` window. `drive` runs doctor itself and refuses on any `FAIL`.

A locked screen fails every `ocu` read with `cgWindowNotFound`, for every app. Only a person at the Mac can unlock it; report the run as blocked rather than retrying.

## Drive

A journey is a JavaScript file run by `ocu js` after `bin/prelude.js`, which binds the run's instance as `app` and provides:

| Name | Use |
| --- | --- |
| `SPANREED` | `{ run, pid, bundle, home, config, files, evidence, journey }` paths and ids |
| `homeNote`, `configFile` | absolute paths of the run's `Home.txt` and `config` |
| `state()`, `waitFor(re, ms)` | read the focused window's accessibility tree; wait until it matches |
| `indexOf(state, re)` | element index of the first tree line matching `re`, e.g. `/ID: note-editor/` |
| `act(description, fn)` | log the user action to `drive.log`, then run `fn` |
| `waitForFile(path, predicate, ms)`, `waitForExit(ms)` | wait for a file side effect; wait for the app to quit |
| `snap(name)`, `pass(message)` | capture evidence; log a `PASS` line |
| `app.click`, `app.typeText`, `app.pressKey`, `app.setValue` | `ocu` actions; keys use xdotool names such as `cmd+n`, `cmd+shift+s`, `Return`, `Escape` |

```sh
spanreed-verify drive home-1 .claude/skills/verify-spanreed/journeys/home-note-autosave.js
spanreed-verify snap home-1 03-after-zoom
```

`drive` prints the journey's `act:`, `snap:`, and `PASS` lines and its exit code; a thrown `Error:` names the step that failed. Write ad hoc journeys in the same shape as `journeys/home-note-autosave.js`, and save reusable ones in `journeys/`.

A state reads like this (from a real run):

```text
App=com.rayfilet.Spanreed.verify.proof-3 (pid 32600)
Window: "home", App: Spanreed.
0 standard window home, Secondary Actions: Raise
	1 scroll area Secondary Actions: Scroll Up, Scroll Down
		2 text entry area (settable, string) ID: note-editor "quoted" -- teh
8 menu bar
	9 Spanreed
	10 File
	...
```

Prefer stable handles: the editor's `ID: note-editor`, the `Window: "<title>"` header (`home`, `Config`, `Untitled`, or the file name), sheet button titles (`Save`, `Don't Save`, `Cancel`), and the menu shortcuts in `features/`. The editor line ends with its text, so `waitFor` on that text confirms what is on screen. `ocu` sees only the app's focused window plus the menu bar; switch windows with `cmd+1` (Home Note) or by closing the front one. The feature map at [`features/README.md`](features/README.md) has the recipe for each feature; read it before driving one, and cover every entry point it lists.

## Evidence

Everything lands in `.build/verify/evidence/<id>/`, which cleanup keeps:

- `<name>.png` and `<name>.ax.txt`: the focused window's screenshot and accessibility tree at each `snap`.
- `<name>.home.txt` and `<name>.config`: copies of the run's files at the same moment.
- `drive.log`: every `act:`, `snap:`, and `PASS` line with timestamps; `<journey>.journey.js` and `<journey>.ocu.log` per drive.
- `build.meta`: git rev, changed-path count, and build hash of the app under test.

Proof standards:

- Drive the user's path: keystrokes, clicks, menus, and panels. Seeding a file with `--home-text` or `--config` sets a precondition; it never proves a behavior.
- Snap before and after the action, so the evidence shows the action and the resulting state.
- Check side effects on disk (`Home.txt`, `config`, files saved into `files/`) as well as the screen. Spanreed's promises are about files: autosave, exact UTF-8, Config rewrites.
- A journey that cannot reach its precondition fails and says why. Record the reason in that feature's `Gotchas`; keep the journey as strict as before.

## Cleanup

```sh
spanreed-verify cleanup home-1
spanreed-verify list
```

`cleanup` stops only the pid recorded for the run, and only while that pid is still the run's app copy. It deletes the run's UserDefaults domains, its Open Recent list, its LaunchServices registration, and `.build/verify/runs/<id>/`, then lists the evidence it kept. Run it after every run, failed ones included. `list` shows runs left behind by earlier attempts; clean each one up.

## Helpers

- `bin/spanreed-verify`: the commands above; `spanreed-verify` with no arguments prints usage.
- `bin/prelude.js`: the journey API in the Drive table.
- `bin/window-probe.swift`: compiled by `launch` into `.build/verify/bin/window-probe`. `window-probe <pid>` prints `locked 0|1` and one `window <id> <onscreen> <title>` line per window; `launch` and `doctor` use it.
- `journeys/`: saved journeys.

Repo regression tests are separate: `xcodebuild test -project Spanreed.xcodeproj -scheme Spanreed -destination 'platform=macOS'` runs XCUITest, which takes over the real keyboard and pointer for the whole suite.
