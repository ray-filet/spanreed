<img src="assets/icon.svg" width="64" height="64" alt="">

# spanreed

Created in [T3 Code](https://t3.codes).

## Build and run

Open `Spanreed.xcodeproj`, select the shared **Spanreed** scheme, and run on your Mac. The project uses AppKit, targets macOS 13 or later, and uses Xcode 16 or later folder-synchronized groups. It signs locally without a development team. App Sandbox is disabled for this local build; see [ADR-0002](docs/adr/0002-local-build-without-app-sandbox.md).

```sh
xcodebuild build -project Spanreed.xcodeproj -scheme Spanreed -destination 'platform=macOS'
xcodebuild test -project Spanreed.xcodeproj -scheme Spanreed -destination 'platform=macOS'
```

`SpanreedCore` is a pure Swift framework. Its public Config behavior is tested in `Tests/SpanreedCoreTests`. App behavior is tested through XCUITest in `Tests/SpanreedUITests`; these tests always launch with temporary Home Note and Config folders.

## Isolated paths

Normal launches use `~/Documents/Spanreed/Home.txt` and `~/.config/spanreed/config`. For tests or isolated runs, set both folders with launch arguments:

```sh
Spanreed.app/Contents/MacOS/Spanreed --home-note-folder /tmp/spanreed-home --config-folder /tmp/spanreed-config
```

The equivalent environment variables are `SPANREED_HOME_NOTE_FOLDER` and `SPANREED_CONFIG_FOLDER`. Arguments take precedence. `SPANREED_DEFAULTS_SUITE` chooses a separate UserDefaults suite for isolated runs.
