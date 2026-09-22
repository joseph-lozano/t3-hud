# T3 HUD

A macOS floating window for your existing T3 Code UI. Use **⌘⌥H** or click the floating T3 icon to show or hide it. Drag the icon to move it; its display-relative position survives relaunch. Clicking another app and pressing Escape leave the HUD visible.

## Install and launch

Requires macOS 13 or later and Xcode command-line tools to build.

```sh
./scripts/install
open "$HOME/Applications/T3 HUD.app"
```

After installation, open **T3 HUD** from Finder or Spotlight. Quit from the **T3** menu bar menu. Quit the previous HUD before reinstalling. The menu also provides a show/hide fallback if another app owns the shortcut.

For development, `./scripts/run` builds and opens `dist/T3 HUD.app`. `swift build` checks compilation. Run the activity bridge checks with `node --test Tests/Bridge/activity.test.cjs`. The UI verification procedure is in [docs/verification-features.md](docs/verification-features.md); this project has no Swift unit-test target.

## Connect to T3

The HUD is a client only: it always loads hosted T3 Connect at `https://app.t3.codes` and never connects to a T3 server address directly. Sign in there to reach your connected environments. Use the same environments as your normal T3 app to see the same threads. T3 Connect handles environment discovery and pairing; T3 stores the browser session, thread selection, and drafts. Direct server addresses saved by earlier builds are discarded on launch.

The wrapper neither starts T3 nor creates a tunnel. In T3 desktop, Settings → Connections contains its network and pairing controls. Changing T3's network setting can restart it.

When T3 Connect is unreachable, the HUD displays a disconnected message and checks for recovery every five seconds. It preserves the loaded page so T3 can reconnect without losing unsent drafts. If the initial page could not load, the HUD loads it when the server returns. **T3 → Reload T3** (**⌘R**) explicitly reloads the page and relies on T3's own draft persistence.

## HUD notifications

A gold comet circles the floating icon while an observed connected thread is working. Its color is HSL 45°, 100%, 56%, with a 2.6-second orbit. The existing red notification-count badge stays at the top right and can appear alongside the comet. With macOS Reduce Motion enabled, activity uses a steady gold ring.

Activity is independent of notification permission. The experimental activity bridge observes T3's existing HTTP shell snapshots and WebSocket shell updates; it creates no requests or additional connections. Pending approval/input and monitoring-only threads do not animate. Closed connections stop contributing activity. Only the aggregate working flag reaches native code. This relies on T3's current wire format and on the shell state received during this HUD session, including HTTP snapshots; it is not a server-wide monitor when the HUD is disconnected.

For T3 Connect, enable notifications in T3 settings and approve **Enable HUD Alerts**. While the HUD is hidden, notifications show the thread title beside the floating icon for eight seconds. A new notification replaces the toast and restarts its timer. Click the toast to open its thread. The icon mirrors T3’s notification badge; T3 controls when that badge clears.

The experimental bridge adapts browser notifications inside the embedded UI. It does not fork T3 or enable macOS Notification Center alerts. Alert permission is remembered per origin. Changes to T3’s notification implementation may require a wrapper update.

## Layout

- `Sources/T3HUD/` — native windows, hotkey, WebKit host, connectivity monitoring.
- `Sources/T3HUDCore/` — display geometry.
- `Tests/UI/` — isolated web and native-window fixtures for UI checks.
- `Resources/Info.plist` — app bundle metadata.
- `scripts/` — build, install, run, and verification helpers.
- `docs/` — design, decisions, and verification notes.

The first prototype is preserved in Git at `1b8fdbc`. Its app identifier remains `local.t3hud.prototype` internally to keep the browser-storage identity used during that experiment. T3 may still request fresh pairing; retaining browser storage does not guarantee that a server session remains authorized. The displayed name and menus are **T3 HUD**. Without a configured identity, builds use an ad-hoc signature for local development. Replacing an ad-hoc build can trigger another Keychain approval for WebKit's encryption key.

## Developer signing

Sign in through Xcode → Settings → Apple Accounts. Select your team, open Manage Certificates, and create or import a Developer ID Application signing identity for builds outside the App Store. The certificate's private key must be present on this Mac.

List available identities with `security find-identity -v -p codesigning`. Save the chosen certificate's fingerprint in the ignored `.signing-identity` file, or pass `T3HUD_SIGNING_IDENTITY` when running `./scripts/build` or `./scripts/install`. Subsequent builds use that identity with hardened runtime and a secure timestamp; an unavailable configured identity fails the build rather than falling back to ad-hoc signing. Keep certificate/private-key exports out of the repository.

Moving from ad-hoc signing to a certificate may require one new Keychain approval. Notarization and public distribution are separate from this local installation.

For a signed, notarized Apple Silicon DMG, use the manually triggered GitHub Actions workflow. See [release setup and build instructions](docs/releases.md) for the required secrets and download steps.
