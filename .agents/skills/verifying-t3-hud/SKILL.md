---
name: verifying-t3-hud
description: Verify the native T3 HUD through an isolated macOS app bundle, owned local web fixture, and recorded user-facing checks.
---

# Verifying T3 HUD

## Launch

Run `./scripts/build`, then `python3 scripts/verification/session.py start`. Save its printed run directory, bundle ID, and app path. The run has unique NSUserDefaults and WebKit storage; it does not inherit real T3 credentials. The Python fixture binds a random loopback port and records its PID plus process start/command identity in `owner.json`. Open only that run's `.app` using `open <app-path>`. Do not launch a second instance owning the global shortcut while the normal HUD is running; quit the normal HUD first or record hotkey testing as blocked.

For fullscreen and focus, compile `Tests/UI/host.swift` with `xcrun swiftc ... -framework AppKit -o <run-directory>/HUDVerificationHost`. Run it only for this proof. It is a blank, disposable normal window. Quit it through its menu afterward.

## Doctor

Run `python3 scripts/verification/session.py doctor <run-directory>`. It verifies the fixture's process ownership, unique response header, bundle identity, and code signature. Inspect the actual HUD with Computer Use and confirm its page displays the same run ID. A healthy endpoint alone is insufficient. Record SHA-256 fingerprints of `Package.swift`, Sources, Resources, and scripts alongside the proof.

## Drive

Use the Computer Use skill and `sky` to inspect and interact with the app by its run-specific bundle ID. Re-query accessibility state before acting. The URL field is labelled `T3 connection URL`. The fixture input is labelled `Unsent draft`. Use the floating `Toggle T3 HUD` icon, and the `T3` menu's Show / Hide and Quit entries. For icon drag and fullscreen controls, derive coordinates from fresh screenshots if accessibility has no suitable action.

The Computer Use driver cannot inject global shortcuts. Ask the user to press Cmd+Option+H with the disposable host active and report show/hide and focus. Do not substitute an app-targeted synthetic key for proof of a global hotkey.

To drop and restore the owned server, run `python3 scripts/verification/session.py offline <run-directory>` and `... online ...`. Observe the disconnected message within eight seconds and subsequent recovery. The fixture's Document ID and draft must remain identical through an already-loaded disconnect cycle. To test initial failure, relaunch while offline and restore online. Never stop the user's T3 backend.

## Evidence

Store commands, AX output, screenshots, fingerprints, and manual observations under `<run-directory>/evidence/`. Do not capture real T3 credentials or conversation text. Public report: `docs/verification.md`. Keep human observations distinct from automated observations and static inspection. Calibrate doctor against the offline fixture: it must exit nonzero, then succeed after restoration.

## Cleanup

Quit only the run-specific app via its Quit menu and the disposable host via its menu. Run `python3 scripts/verification/session.py cleanup <run-directory>`. It refuses unknown directories and mismatched fixture process identities, stops only the owned fixture, and deletes only that run's preferences. It leaves proof, the scratch bundle, and its isolated WebKit store for inspection. Do not delete real T3/HUD storage. Record any remaining scratch resources explicitly.

## Feature map

Follow `docs/verification-features.md`. A real authenticated T3 smoke check is read-only unless the user approves exact message content. The user's prior prototype prompt validates the upstream UI flow, but is not evidence for a changed build's hotkey or lifecycle behavior.
