# Classic Notes

Every Note other than the Home Note saves the classic way: a new Note opens as `Untitled`, Command-S writes it to a file the user picks, closing it with unsaved changes asks first, and opened files are read and written as UTF-8 only.

## Sub-features

- `classic-new`: Command-N opens a separate `Untitled` window with the editor focused.
- `classic-save`: Command-S on an Untitled Note opens a save sheet; the saved file holds the exact text and the window title becomes the file name.
- `classic-close-prompt`: Command-W with unsaved changes shows a sheet with `Save`, `Don't Save`, and `Cancel`; a saved Note closes with no sheet.
- `classic-open`: Command-O opens any extension; a file that is not valid UTF-8 shows an alert and stays unchanged.
- `classic-recent`: File → Open Recent lists Notes opened in the run and reopens one.

## How to get to it (user POV)

- File → New, or Command-N.
- File → Open…, or Command-O.
- File → Open Recent → the file name.
- File → Save (Command-S), File → Save As… (Command-Shift-S), File → Close (Command-W).

## Driving it with spanreed-verify

Preconditions:

- A running run; `doctor` passes.
- For `classic-open` and `classic-recent`, seed files before driving: `printf 'Café 日本' > .build/verify/runs/<id>/files/Saved.txt` and `printf 'fo\x80\xff' > .build/verify/runs/<id>/files/Invalid.txt`.

- **New.** `await act("New", () => app.pressKey("cmd+n")); await waitFor(/Untitled/)`, then `snap`. The focused window is `Untitled` and the `home` window is unchanged.
- **Unsaved prompt.** `await app.typeText("Keep this note")`, then `await act("Close", () => app.pressKey("cmd+w")); await waitFor(/Don.t Save/)`. A sheet offers `Save`, `Don't Save`, and `Cancel`. Click `Cancel` by index; the text is still there.
- **Save.** `await act("Save", () => app.pressKey("cmd+s"))`, `cmd+shift+g`, type `SPANREED.files + "/New note.txt"`, `Return`, click `Save`. `waitForFile(SPANREED.files + "/New note.txt", t => t === "Keep this note")` passes and the window title becomes `New note.txt`. Command-W then closes it with no sheet.
- **Open.** `await act("Open", () => app.pressKey("cmd+o"))`, `cmd+shift+g`, type `SPANREED.files + "/Saved.txt"`, `Return`, click `Open`. A `Saved.txt` window shows `Café 日本`. Add text, Command-S, and `Saved.txt` holds the new UTF-8 bytes.
- **Invalid UTF-8.** Open `Invalid.txt` the same way. An alert says the file could not be opened; after `Return`, no new window exists and `Invalid.txt` still holds its four original bytes.
- **Open Recent.** Close `Saved.txt`, then open File → Open Recent → `Saved.txt` through the menu bar. The `Saved.txt` window returns with its text.

## Gotchas

- Save and Open panels start in the user's last folder. Always jump to `SPANREED.files` with `cmd+shift+g`.
- The sheet's `Don't Save` button may read with a curly apostrophe; match it with `/Don.t Save/`.
- Open Recent is per bundle id, so each run starts with an empty list and never touches the user's. `Clear Menu` clears only the run's list.
- Open Recent has no shortcut. The state lists `File` under `menu bar`; opening its submenu by click is not yet driven. If the submenu never appears, report `classic-recent` unreached; a reopen through Command-O does not count for it.
- Save As on a classic Note moves the Note to the new file; later saves go there.
