<img src="assets/icon.svg" width="64" height="64" alt="">

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
