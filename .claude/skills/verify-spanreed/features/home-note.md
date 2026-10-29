# Home Note

The Home Note is the one Note Spanreed opens on every launch, in a window titled `home`. It saves to `Home.txt` on every keystroke as exact plain text, never prompts to save, and comes back with its text after quitting.

## Sub-features

- `home-first-launch`: first launch creates an empty `Home.txt` and opens one `home` window with the editor focused.
- `home-autosave`: typing, Undo, and Redo write `Home.txt` at once, with no smart quotes, smart dashes, or autocorrect.
- `home-quit-restore`: Command-Q quits without a prompt; the next launch shows the same text.
- `home-recreate`: a `Home.txt` deleted or moved while Spanreed is closed comes back empty on the next launch.
- `home-reopen`: closing the `home` window leaves Spanreed running; Window → home (Command-1) or a Dock click brings it back.
- `home-save-as-copy`: Save As (Command-Shift-S) writes a copy, and the window keeps autosaving `Home.txt`.

## How to get to it (user POV)

- Launch Spanreed: the Home Note is the first and only window.
- Choose Window → home, or press Command-1.
- Click the Dock icon while no Spanreed window is open.

## Driving it with spanreed-verify

Preconditions:

- A fresh run with no `--home-text` seed, so `Home.txt` starts empty.
- `spanreed-verify doctor <id>` passes.

- **First launch.** Run `spanreed-verify launch home-1`, then `spanreed-verify snap home-1 01-launched`. `READY` prints, `01-launched.home.txt` is empty, and `01-launched.ax.txt` shows `Window: "home"` and an empty `ID: note-editor` line.
- **Autosave.** Run `spanreed-verify drive home-1 .claude/skills/verify-spanreed/journeys/home-note-autosave.js`. It prints `PASS Home.txt on disk holds exactly the typed text`, and `02-typed.home.txt` is `"quoted" -- teh` with straight quotes and `teh` uncorrected.
- **Undo and Redo.** `await act("undo", () => app.pressKey("cmd+z")); await waitForFile(homeNote, t => t === "")`, then `await act("redo", () => app.pressKey("cmd+shift+z")); await waitForFile(homeNote, t => t === typed)`. `Home.txt` empties, then holds the text again.
- **Quit and restore.** `await act("quit", () => app.pressKey("cmd+q")); await waitForExit()`, then run `spanreed-verify relaunch home-1` and `spanreed-verify snap home-1 03-relaunched`. The process exits within 5 s with no sheet, and `03-relaunched.ax.txt` shows the typed text in the `home` window.
- **Recreate.** After a quit, run `mv .build/verify/runs/home-1/home/Home.txt .build/verify/runs/home-1/files/Moved.txt` and `spanreed-verify relaunch home-1`. `Home.txt` exists again, empty, and the editor is empty.
- **Reopen.** `await act("close home", () => app.pressKey("cmd+w"))`; `window-probe <pid>` shows no `home` window while `spanreed-verify list` still reports the run running. Then `await act("Window → home", () => app.pressKey("cmd+1")); await waitFor(/ID: note-editor/)`. The window returns with its text.
- **Save As copy.** `await act("Save As", () => app.pressKey("cmd+shift+s"))`, `cmd+shift+g`, type `SPANREED.files + "/Copy.txt"`, `Return`, then the panel's `Save` button. `files/Copy.txt` holds the text; typing more updates `Home.txt` and leaves `Copy.txt` unchanged.

## Gotchas

- The window title and the Window menu item are both lowercase `home`.
- `launch` refuses an existing run id. Use `relaunch` for restore checks; a new `launch` starts with an empty Home Note.
- With the `home` window closed, Spanreed has no window, and the next `ocu` read activates the app and takes focus from the user.
- `relaunch` reuses the run's copy of the build. After a code change, launch a new run.
- A fresh run always opens the window centered; frame restore applies only after the run itself moves or resizes the window.
