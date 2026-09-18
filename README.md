# T3 HUD

A macOS floating window for your existing T3 Code UI. Use **⌘⌥H** or click the floating T3 icon to show or hide it. Drag the icon to move it; its display-relative position survives relaunch. Clicking another app and pressing Escape leave the HUD visible.

## Install and launch

Requires macOS 13 or later and Xcode command-line tools to build.

```sh
./scripts/install
open "$HOME/Applications/T3 HUD.app"
```

After installation, open **T3 HUD** from Finder or Spotlight. Quit from the **T3** menu bar menu. Quit the previous HUD before reinstalling. The menu also provides a show/hide fallback if another app owns the shortcut.

For development, `./scripts/run` builds and opens `dist/T3 HUD.app`. `swift build` checks compilation. The UI verification procedure is in [docs/verification-features.md](docs/verification-features.md); this project currently has no unit-test suite.

## Connect to T3

Paste your T3 server URL or pairing link in the connection field and click **Connect**. Use the same environment as your normal T3 app to see the same threads. The HUD remembers the connection address without query parameters, fragments, or pairing credentials. T3 stores the browser session and handles thread selection and drafts. Pairing links are only needed for initial authorization or after revocation.

The wrapper neither starts T3 nor creates a tunnel. In T3 desktop, Settings → Connections contains its network and pairing controls. Changing T3's network setting can restart it. If your server address changes, enter the new address in the HUD.

When the server is unavailable, the HUD displays a disconnected message and checks for recovery every five seconds. It preserves the loaded page so T3 can reconnect without losing unsent drafts. If the initial page could not load, the HUD loads it when the server returns. **Reload** explicitly reloads the page and relies on T3's own draft persistence.

## Layout

- `Sources/T3HUD/` — native windows, hotkey, WebKit host, connectivity monitoring.
- `Sources/T3HUDCore/` — connection URL handling and display geometry.
- `Tests/UI/` — isolated web and native-window fixtures for UI checks.
- `Resources/Info.plist` — app bundle metadata.
- `scripts/` — build, install, run, and verification helpers.
- `docs/` — design, decisions, and verification notes.

The first prototype is preserved in Git at `1b8fdbc`. Its app identifier remains `local.t3hud.prototype` internally to keep the browser-storage identity used during that experiment. T3 may still request fresh pairing; retaining browser storage does not guarantee that a server session remains authorized. The displayed name and menus are **T3 HUD**. The app is locally ad-hoc signed, suitable for personal use; distribution signing is outside this MVP.
