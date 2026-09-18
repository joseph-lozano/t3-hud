# T3 HUD native prototype

THROWAWAY. Answers whether T3's existing web UI works inside a retained macOS panel. This is an integration spike, not a replacement T3 client.

Run from the repository root:

```sh
./prototype/native-webview/run
```

Requires macOS and Xcode command-line tools. No dependencies to install. Quit the existing prototype from the `T3 P` menu before running a second copy.

The panel opens against `http://127.0.0.1:3773`. This is a starting address, not automatic discovery. Paste a different T3 URL or a supported pairing link into the top field and choose Load. The field strips query/fragment credentials after loading; diagnostic output contains no URLs or tokens.

Use Command+Option+H or the floating T3 icon to hide/show. Escape and switching apps should leave the panel visible. The menu bar's `T3 P` menu also provides Quit. The bottom diagnostic line reports shortcut registration, visibility, toggle count, navigation count, and load status. A loaded page does not establish authentication.

T3 owns all thread, draft, and connection state. The wrapper keeps the same WKWebView alive while hidden and uses WebKit's persistent website store under its separate app identity, `local.t3hud.prototype`. No desktop credentials are extracted, no custom thread state is written, and no backend is started.

## Pairing

The current T3 desktop installation serves its pairing page but does not yet authorize this browser. Its Network access setting is off. T3's supported connection settings expose pairing links after network access is configured. Changing that setting may restart T3, including the backend serving this coding session. Complete that setup at a suitable point, then load the issued link directly in the prototype. Do not paste credentials into chat or commit them.

## Manual experiment

1. Pair the prototype with the same environment as the main T3 window.
2. Confirm the same existing threads appear.
3. Open a thread and type an unsent draft.
4. Toggle off/on using the icon, then the global hotkey while another app is active. The draft and selected thread should remain, and the load counter should not increase.
5. Check Escape and clicking another app do not hide the panel.
6. Check typing after reopening and focus after dismissing.
7. Send a prompt you choose and observe it in the main T3 window. Automated test messages require approval of their exact text under this workspace's policy.
8. Test an unavailable address such as `http://127.0.0.1:1`; the diagnostic footer should report disconnected without launching T3.

## Prototype limits

The icon is fixed, not draggable. Placement uses the reference's initial icon position and adjacent panel layout, but display-change handling and remembered icon position are deferred. No fullscreen or multi-monitor claims are established. Native file dialogs, downloads, external links, and all T3 workflows remain unverified. The disconnected presentation is only a diagnostic footer. Network reconnection and address persistence are not implemented.

See [VERDICT.md](VERDICT.md) for observed results. The prototype is preserved on `prototype/native-webview`; agreed design documents are on `main`.
