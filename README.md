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

For T3 Connect, enter `https://app.t3.codes` and sign in to access your connected environments.

The connection bar is hidden by default. Open **T3 → Show Connection Bar** or press **⌘L**, paste your T3 server URL or pairing link, and click **Connect**. The bar hides after connecting; the same menu or shortcut can hide it without reloading the page. Use the same environment as your normal T3 app to see the same threads. The HUD remembers the connection address without query parameters, fragments, or pairing credentials. T3 stores the browser session and handles thread selection and drafts. Pairing links are only needed for initial authorization or after revocation.

The wrapper neither starts T3 nor creates a tunnel. In T3 desktop, Settings → Connections contains its network and pairing controls. Changing T3's network setting can restart it. If your server address changes, enter the new address in the HUD.

When the server is unavailable, the HUD displays a disconnected message and checks for recovery every five seconds. It preserves the loaded page so T3 can reconnect without losing unsent drafts. If the initial page could not load, the HUD loads it when the server returns. **Reload** explicitly reloads the page and relies on T3's own draft persistence.

## HUD notifications

For T3 Connect, enable notifications in T3 settings and approve **Enable HUD Alerts**. While the HUD is hidden, notifications show the thread title beside the floating icon for eight seconds. A new notification replaces the toast and restarts its timer. Click the toast to open its thread. The icon mirrors T3’s notification badge; T3 controls when that badge clears.

The experimental bridge adapts browser notifications inside the embedded UI. It does not fork T3 or enable macOS Notification Center alerts. Alert permission is remembered per origin. The bridge currently supports hosted T3 Connect; direct server URLs can display the UI but do not receive bridge alerts. Changes to T3’s notification implementation may require a wrapper update.

## Layout

- `Sources/T3HUD/` — native windows, hotkey, WebKit host, connectivity monitoring.
- `Sources/T3HUDCore/` — connection URL handling and display geometry.
- `Tests/UI/` — isolated web and native-window fixtures for UI checks.
- `Resources/Info.plist` — app bundle metadata.
- `scripts/` — build, install, run, and verification helpers.
- `docs/` — design, decisions, and verification notes.

The first prototype is preserved in Git at `1b8fdbc`. Its app identifier remains `local.t3hud.prototype` internally to keep the browser-storage identity used during that experiment. T3 may still request fresh pairing; retaining browser storage does not guarantee that a server session remains authorized. The displayed name and menus are **T3 HUD**. Without a configured identity, builds use an ad-hoc signature for local development. Replacing an ad-hoc build can trigger another Keychain approval for WebKit's encryption key.

## Developer signing

Sign in through Xcode → Settings → Apple Accounts. Select your team, open Manage Certificates, and create or import a Developer ID Application signing identity for builds outside the App Store. The certificate's private key must be present on this Mac.

List available identities with `security find-identity -v -p codesigning`. Save the chosen certificate's fingerprint in the ignored `.signing-identity` file, or pass `T3HUD_SIGNING_IDENTITY` when running `./scripts/build` or `./scripts/install`. Subsequent builds use that identity with hardened runtime and a secure timestamp; an unavailable configured identity fails the build rather than falling back to ad-hoc signing. Keep certificate/private-key exports out of the repository.

Moving from ad-hoc signing to a certificate may require one new Keychain approval. Notarization and public distribution are separate from this local installation.
