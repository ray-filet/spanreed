# Spanreed verification map

This directory is the maintained source for verifying Spanreed's user-facing behavior. Read the index, then use the matching feature file as the recipe.

## Baseline preconditions

- A run started with `spanreed-verify launch <id>` from an empty run, unless the feature seeds `--home-text` or `--config`.
- `spanreed-verify doctor <id>` passes. A `FAIL screen is locked` blocks every recipe.
- Files a recipe opens or saves live in the run's `files/` folder (`SPANREED.files` in a journey).
- Drive only the run's bundle id, `com.rayfilet.Spanreed.verify.<id>`.

## Driving conventions

- Each recipe step pairs a user action with the journey line that performs it and the observable result.
- Journeys run through `spanreed-verify drive <id> <journey.js>`; the API is the Drive table in `../SKILL.md`.
- Reach menu items through their keyboard shortcut when one exists. Items with no shortcut (Appearance, Font, Open Recent) go through the menu bar, which every state lists under `menu bar` (`Spanreed`, `File`, `Edit`, `Format`, `View`, `Window`): click the top item by index, then re-read for its submenu.
- `ocu` sees only the focused window plus the menu bar. Bring the intended window to the front before reading it.
- Match the editor with `/ID: note-editor/`. Its tree line ends with the editor's text.
- Panels (Save, Open) always go to the run's `files/` folder with `cmd+shift+g`, so nothing lands in the user's folders.

## Proof and skip reporting

- `snap` before and after each action; name snaps in order (`01-…`, `02-…`).
- A file side effect is proved by `waitForFile`, not by the screen alone.
- Record the feature's sub-feature ID and entry point in the journey name or `act` description.
- Report an unreachable entry point with the journey line that failed and the unmet precondition. A behavior proved through one entry point stays unproved for the others.

## Feature entry contract

Each feature file starts with an H1 title and one paragraph describing the user-visible behavior, then exactly four H2 sections in this order:

1. `Sub-features`: short IDs, one line each.
2. `How to get to it (user POV)`: every user entry point.
3. `Driving it with spanreed-verify`: starts with `Preconditions:`, then labeled bullets pairing each user action with the journey line and observable result.
4. `Gotchas`: traps that waste or invalidate a run.

## Features

Driven end to end so far: `home-autosave` only, through `journeys/home-note-autosave.js` (run `proof-3`, rev `c59e5c9`). Every other recipe still needs its first run; correct its handles in place on that run.

- [Home Note](./home-note.md): first launch, autosave, quit and restore, recreate, reopen, Save As copy.
- [Classic Notes](./classic-notes.md): new, save, unsaved-changes prompt, open, Open Recent.
- [Text size](./text-size.md): increase, decrease, reset, every window, persistence.
- [Config](./config.md): defaults on launch, open, edit and apply, error alert, preservation.
- [Appearance and fonts](./appearance-and-fonts.md): View → Appearance and Format → Font.

Not yet mapped: Tab and Shift+Tab indentation, Find and Replace, formatted paste arriving as plain text.
