<img src="Sources/Spanreed/Assets.xcassets/AppIcon.appiconset/icon_128x128.png" width="80" height="80" alt="">

# spanreed

Created in [T3 Code](https://t3.codes).

## Build and run

Open `Spanreed.xcodeproj`, select the shared **Spanreed** scheme, and run on your Mac. The project uses AppKit, targets macOS 13 or later, and uses Xcode 16 or later folder-synchronized groups. It signs locally without a development team. App Sandbox is disabled for this local build; see [ADR-0002](docs/adr/0002-local-build-without-app-sandbox.md).

```sh
xcodebuild build -project Spanreed.xcodeproj -scheme Spanreed -destination 'platform=macOS'
xcodebuild test -project Spanreed.xcodeproj -scheme Spanreed -destination 'platform=macOS'
```

To build and open the standalone Release app:

```sh
xcodebuild build -project Spanreed.xcodeproj -scheme Spanreed -configuration Release -destination 'platform=macOS' -derivedDataPath .build/release
python3 scripts/check-app-launch.py .build/release/Build/Products/Release/Spanreed.app
open .build/release/Build/Products/Release/Spanreed.app
```

The launch check copies the app to a temporary folder and runs it without Xcode's library search paths, using isolated Home Note, Config, and UserDefaults locations. It checks that the app creates its Home Note and stays open. Run this after changing framework or packaging settings, since a successful build or XCTest run can miss a broken standalone launch.

`SpanreedCore` is a pure Swift framework. Its public Config and indentation behavior is tested in `Tests/SpanreedCoreTests`. App behavior is tested through XCUITest in `Tests/SpanreedUITests`; these tests always launch with temporary Home Note and Config folders.

## Install without Xcode

GitHub Actions builds the Release app on every push to `main` that changes the app, and publishes it as the **Latest build** release.

1. Download [Spanreed.zip](https://github.com/ray-filet/spanreed/releases/latest/download/Spanreed.zip). Sign in to GitHub first, because the repository is private.
2. Unzip it and move `Spanreed.app` to `/Applications`, or to `~/Applications` without admin rights.
3. Clear the download quarantine. The app is signed locally, not with a Developer ID, so Gatekeeper blocks it otherwise. Run the line that matches the folder you chose in step 2:

   ```sh
   xattr -dr com.apple.quarantine /Applications/Spanreed.app
   xattr -dr com.apple.quarantine ~/Applications/Spanreed.app
   ```

The app runs on Apple silicon and Intel Macs with macOS 13 or later. To build on demand, run the **Release** workflow from the repository's Actions tab.

## Config and text size

Spanreed creates `~/.config/spanreed/config` on launch and writes every supported setting, including defaults. Existing Config files gain any missing settings on launch or save; comments, explicit values, and line endings are preserved. Open Config with **Command-,** and save to apply edits.

When `selected-fonts` is absent, Spanreed fills it with SF Mono followed by every monospaced font family installed on the Mac, in alphabetical order (on a stock macOS install: Andale Mono, Courier New, Menlo, Monaco, PT Mono). Existing `selected-fonts` values are never changed, and fonts installed later are not added automatically.

`font-size` is the default text size used by **Command-0**. `current-text-size` is the size currently displayed in every Note, saved by the zoom commands and restored on launch. Editing either value leaves the other independent; if `current-text-size` is missing, it starts at `font-size`. Saved zoom from older versions is migrated from UserDefaults when Config has no current size. Window position remains separate app state.

## Indentation

Tab inserts a tab at the caret. Shift+Tab outdents the current line or all selected lines by one level, removing one leading tab or up to four leading spaces. It keeps the caret or selection in place relative to the text and supports Undo and Redo.

## Appearance

Choose **View → Appearance → System, Light, or Dark**. The choice applies to all Note windows and is saved to Config as `appearance = system`, `appearance = light`, or `appearance = dark`. System follows the Mac's appearance. You can also edit `appearance` in Spanreed's Config window and save to apply it.

## Isolated paths

Normal launches use `~/Documents/Spanreed/Home.txt` and `~/.config/spanreed/config`. For tests or isolated runs, set both folders with launch arguments:

```sh
Spanreed.app/Contents/MacOS/Spanreed --home-note-folder /tmp/spanreed-home --config-folder /tmp/spanreed-config
```

The equivalent environment variables are `SPANREED_HOME_NOTE_FOLDER` and `SPANREED_CONFIG_FOLDER`. Arguments take precedence. `SPANREED_DEFAULTS_SUITE` chooses a separate UserDefaults suite for isolated runs.
