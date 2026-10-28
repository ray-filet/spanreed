<img src="Sources/Spanreed/Assets.xcassets/AppIcon.appiconset/icon_128x128.png" width="80" height="80" alt="">

# Spanreed

A minimal macOS plain-text editor for quick notes. It opens straight to a page you can type on and saves as you type.

## Why it exists

TextEdit is slow for jotting things down. It opens to a file picker instead of a page, switching a document to plain text takes several steps every time, and text size has to be set window by window.

Spanreed opens to the **Home Note**, one plain-text file at `~/Documents/Spanreed/Home.txt` that saves as you type and comes back with its text on every launch. You can still create, open, and save other text files the usual way. Text is large by default (SF Mono at 20 pt), and one font and size apply to every window. Settings live in a plain-text Config file you edit by hand, in the style of [Ghostty](https://ghostty.org).

## What it does

- Opens to the Home Note with no file picker and no untitled window. Quitting never asks to save it.
- Other notes (**Command-N**, **Command-O**, **File → Open Recent**) use classic saving with **Command-S** and a prompt for unsaved changes.
- Plain text only, read and written as UTF-8. Smart quotes, smart dashes, text replacement, and auto-correct are off, so text stays exactly as you typed it.
- One font and one text size across all windows, changed with **Command-+**, **Command-−**, and **Command-0**.
- Light, Dark, or System appearance, Tab and Shift+Tab indentation, undo, and find and replace.

It deliberately leaves out syntax highlighting, line numbers, tabs, rich text, iCloud sync, and a settings window.

## Install

Spanreed runs on Apple silicon and Intel Macs with macOS 13 or later. GitHub Actions builds the app on every push to `main` that changes it and publishes it as the **Latest build** release.

1. Download [Spanreed.zip](https://github.com/ray-filet/spanreed/releases/latest/download/Spanreed.zip).
2. Unzip it in `~/Downloads`, if your browser has not already.
3. Move the app to `/Applications`, replacing any previous copy, and clear the download quarantine. The app is not signed with a Developer ID or notarized, so Gatekeeper blocks it otherwise:

   ```sh
   rm -rf /Applications/Spanreed.app
   mv ~/Downloads/Spanreed.app /Applications/
   xattr -dr com.apple.quarantine /Applications/Spanreed.app
   ```

App Sandbox is off, so Spanreed can write the Home Note and Config at fixed paths in your home folder without asking for a folder; see [ADR-0002](docs/adr/0002-local-build-without-app-sandbox.md).

## Home Note

The Home Note is created on first launch and reopens, with its text and window position, on every launch. If the file is deleted or moved while Spanreed is closed, the next launch starts a new empty one. Closing its window does not quit Spanreed. Bring it back with **Window → home** (**Command-1**) or by clicking the Dock icon. **Save As** on the Home Note saves a copy and leaves the Home Note where it is.

## Config and text size

Spanreed creates `~/.config/spanreed/config` on launch and writes every supported setting, including defaults. Existing Config files gain any missing settings on launch or save; comments, explicit values, and line endings are preserved. Open Config with **Command-,** and save to apply edits.

When `selected-fonts` is absent, Spanreed fills it with SF Mono followed by every monospaced font family installed on the Mac, in alphabetical order (on a stock macOS install: Andale Mono, Courier New, Menlo, Monaco, PT Mono). Existing `selected-fonts` values are never changed, and fonts installed later are not added automatically.

`font-size` is the default text size used by **Command-0**. `current-text-size` is the size currently displayed in every Note, saved by the zoom commands and restored on launch. Editing either value leaves the other independent; if `current-text-size` is missing, it starts at `font-size`. Saved zoom from older versions is migrated from UserDefaults when Config has no current size. Window position remains separate app state.

## Indentation

Tab inserts a tab at the caret. Shift+Tab outdents the current line or all selected lines by one level, removing one leading tab or up to four leading spaces. It keeps the caret or selection in place relative to the text and supports Undo and Redo.

## Appearance

Choose **View → Appearance → System, Light, or Dark**. The choice applies to all Note windows and is saved to Config as `appearance = system`, `appearance = light`, or `appearance = dark`. System follows the Mac's appearance. You can also edit `appearance` in Spanreed's Config window and save to apply it.

## Build from source

Open `Spanreed.xcodeproj`, select the shared **Spanreed** scheme, and run on your Mac. The project uses AppKit (see [ADR-0001](docs/adr/0001-appkit-not-swiftui.md)), targets macOS 13 or later, and uses Xcode 16 or later folder-synchronized groups. It signs locally without a development team.

```sh
xcodebuild build -project Spanreed.xcodeproj -scheme Spanreed -destination 'platform=macOS'
xcodebuild test -project Spanreed.xcodeproj -scheme Spanreed -destination 'platform=macOS'
```

To build the Release app, check that it launches, and install it as `/Applications/Spanreed.app`, run `scripts/install`. To build and open the standalone Release app without installing it:

```sh
xcodebuild build -project Spanreed.xcodeproj -scheme Spanreed -configuration Release -destination 'platform=macOS' -derivedDataPath .build/release
python3 scripts/check-app-launch.py .build/release/Build/Products/Release/Spanreed.app
open .build/release/Build/Products/Release/Spanreed.app
```

The launch check copies the app to a temporary folder and runs it without Xcode's library search paths, using isolated Home Note, Config, and UserDefaults locations. It checks that the app creates its Home Note and stays open. Run this after changing framework or packaging settings, since a successful build or XCTest run can miss a broken standalone launch.

`SpanreedCore` is a pure Swift framework. Its public Config and indentation behavior is tested in `Tests/SpanreedCoreTests`. App behavior is tested through XCUITest in `Tests/SpanreedUITests`; these tests always launch with temporary Home Note and Config folders. Domain terms such as Note, Home Note, and Config are defined in [GLOSSARY.md](GLOSSARY.md).

To build a release on demand, run the **Release** workflow from the repository's Actions tab.

## Isolated paths

Normal launches use `~/Documents/Spanreed/Home.txt` and `~/.config/spanreed/config`. For tests or isolated runs, set both folders with launch arguments:

```sh
Spanreed.app/Contents/MacOS/Spanreed --home-note-folder /tmp/spanreed-home --config-folder /tmp/spanreed-config
```

The equivalent environment variables are `SPANREED_HOME_NOTE_FOLDER` and `SPANREED_CONFIG_FOLDER`. Arguments take precedence. `SPANREED_DEFAULTS_SUITE` chooses a separate UserDefaults suite for isolated runs.

---

Created in [T3 Code](https://t3.codes).
