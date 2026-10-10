# T3 HUD

T3 HUD shows [T3 Code](https://app.t3.codes) in a floating macOS window. Press ⌘⌥H or click the floating T3 icon to show or hide it. Drag the icon to move it.

## Install

You need macOS 13 or later and the Xcode command-line tools.

```sh
./scripts/install
open "$HOME/Applications/T3 HUD.app"
```

Quit from the T3 menu in the menu bar. That menu also has a show/hide item for when another app owns the shortcut. Quit the running HUD before you reinstall.

A manually triggered GitHub Actions workflow builds signed, notarized Apple Silicon DMGs. See [docs/releases.md](docs/releases.md).

## Usage

The HUD loads T3 Connect at `https://app.t3.codes`. Sign in there to reach your environments. The HUD doesn't start T3 or connect to T3 servers directly.

To use T3's nightly build, choose **T3 → Update Channel → Nightly**. This sets the same channel as the track selector in T3's About panel and reloads the page. You stay on `app.t3.codes`, so you don't need to sign in again.

If the connection drops, the HUD keeps the page open, so your drafts survive, and reconnects on its own. Press ⌘R to reload.

A gold comet circles the icon while a thread is working.

To get alerts, enable notifications in T3 and approve **Enable HUD Alerts**. While the HUD is hidden, each alert shows the thread title beside the icon. Click it to open the thread. The icon badge counts the threads T3 marks **Done** and stays until you read them. When none are Done, it shows T3's own notification badge.

## Development

```sh
./scripts/run                                # build and open dist/T3 HUD.app
swift build                                  # check that it compiles
node --test Tests/Bridge/activity.test.cjs   # run the activity bridge tests
```

The UI verification steps are in [docs/verification-features.md](docs/verification-features.md).

To sign builds with a Developer ID certificate, run `security find-identity -v -p codesigning` and copy its fingerprint into `.signing-identity`, or set `T3HUD_SIGNING_IDENTITY`. Without either, the build uses an ad-hoc signature.
