# T3 HUD design

## Agreed scope

- Build a HUD wrapper for T3 Code, using https://github.com/pingdotgg/t3code as upstream.
- Use https://github.com/finna/herdr-hud as an interaction reference.
- Summon and dismiss the HUD with a hotkey.
- Target macOS for the MVP. Linux is a possible later addition.
- Optimize for checking threads and sending new prompts.
- The MVP is for personal use. An upstream contribution is a possibility, not an MVP requirement.
- Host the existing T3 UI in a separate wrapper for the MVP.
- Keep the HUD open after sending a prompt.
- Dismiss only with the hotkey or floating icon. Clicking another app does not dismiss it.
- The HUD is a companion used while in other apps. It must show the same threads as the normal T3 interface.
- Use Cmd+Option+H to toggle the T3 view.
- When T3 is unavailable, show an informational disconnected view. Do not launch T3 or offer a launch button.
- Restore the HUD's own selected thread and unfinished draft on reopening; do not follow the main T3 window's selection.
- Use T3's existing client behavior for selection and drafts. Retain the webview while hidden and use persistent browser storage; do not implement a separate state system or promise persistence beyond what T3 supports.
- Use T3's supported network/pairing flow. Network support is in scope; a strictly local-only integration is not required.
- The wrapper only displays T3's existing UI. Reuse T3's connection flow; do not build a custom client protocol, backend, or tunnel service.
- Copy Herdr's focus behavior: opening makes the panel key and focuses its webview; dismissal hides the panel without destroying the webview. Do not add explicit previous-app activation initially.
- Follow Herdr HUD's placement behavior as detailed below, except Escape must not dismiss the view.

## Reference placement

Source: https://github.com/finna/herdr-hud/blob/main/Sources/HerdrHUD/App.swift

- A draggable icon determines which display hosts the panel. Herdr uses 64 by 64 points; the user requested a smaller circular T3 button, so this app uses 48 by 48 points.
- Initial icon position is 32 points from the screen's left edge and 180 points from its bottom edge.
- Persist the icon's screen-relative position and screen ID. Fall back to the first screen when the saved screen is unavailable.
- Start the panel at 940 by 650 points, with a minimum of 640 by 430.
- Place the panel 12 points to the icon's right when it fits, otherwise to its left. Align top edges and clamp to usable screen bounds with 12-point margins.
- Moving the icon moves the panel. Display changes restore icon placement and reposition the panel.
- Retain panel size across hide/show; restart at the default size on relaunch, as the reference does.
- Keep the icon and panel available across Spaces and fullscreen auxiliary layers. Actual behavior needs macOS verification.

## Environment findings

- T3 Code Nightly is installed and running locally with a server observed at 127.0.0.1:3773.
- That address is an observation, not a fixed integration contract.
- The server returns a browser app shell. Authentication and connection discovery for the wrapper remain under investigation.
- Upstream desktop pairing UI exposes Create link when Network access or Tailscale HTTPS is enabled. The user accepts using T3's network support; exact endpoint/setup remains to be chosen.
- Quitting T3 stops its desktop-owned backend. Closing its windows on macOS leaves the app and backend running.

## Prior art search

GitHub searches found related proposals but no verified implementation matching this MVP. This does not rule out private or unindexed work.

- https://github.com/pingdotgg/t3code/issues/1207 proposes a global-hotkey chat overlay for the author's fork. Implementation is unverified.
- https://github.com/pingdotgg/t3code/issues/5511 requests tray/menu-bar controls, rather than a floating HUD.

## Implementation checks

- Verify loading and pairing T3's existing UI in the wrapper using T3's supported connection flow.
- Verify that the wrapper shows the same threads as the normal T3 interface and can send prompts.
- Verify native webview compatibility and retention of T3's own state across hide/show.
- Verify icon placement, hotkey handling, Spaces, fullscreen behavior, and keyboard focus on macOS.
- Verify informational disconnected behavior when the backend becomes unavailable.

The user confirmed shared understanding. The prototype established pairing, shared threads, and prompt sending. The MVP adds credential-free connection URL persistence, a draggable icon with remembered display-relative placement, and normal macOS app packaging. T3 Connect remains T3's own environment-discovery flow.

Verification covers the public app UI: launching, connecting, dragging, toggling, focus, fullscreen, and server recovery. The native Computer Use driver cannot generate global shortcuts; those checks require a recorded physical keypress by the user.
