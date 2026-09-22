# T3 HUD

A floating macOS window for [T3 Code](https://app.t3.codes). Press **⌘⌥H** or click the floating T3 icon to show or hide it. Drag the icon to move it.

## Install

Requires macOS 13+ and the Xcode command-line tools.

```sh
./scripts/install
open "$HOME/Applications/T3 HUD.app"
```

Quit from the **T3** menu bar menu, which also has a show/hide fallback if another app owns the shortcut. Quit the running HUD before reinstalling.

Signed, notarized Apple Silicon DMGs are built by a manual GitHub Actions workflow — see [docs/releases.md](docs/releases.md).

## Usage

The HUD loads T3 Connect at `https://app.t3.codes`. Sign in there to reach your environments; it doesn't start T3 or connect to servers directly. If the connection drops, the HUD keeps the page (and your drafts) and reconnects automatically. **⌘R** reloads.

- **Activity:** a gold comet circles the icon while a thread is working.
- **Notifications:** enable notifications in T3 and approve **Enable HUD Alerts**. While the HUD is hidden, alerts appear as a toast beside the icon; click it to open the thread. The icon mirrors T3's badge count.

## Development

```sh
./scripts/run                                # build and open dist/T3 HUD.app
swift build                                  # compile check
node --test Tests/Bridge/activity.test.cjs   # activity bridge tests
```

UI verification steps are in [docs/verification-features.md](docs/verification-features.md).

To sign builds with a Developer ID certificate, put its fingerprint (from `security find-identity -v -p codesigning`) in `.signing-identity` or set `T3HUD_SIGNING_IDENTITY`. Otherwise builds are ad-hoc signed.
