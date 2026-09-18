# Native webview experiment

Primary source: commit `1b8fdbc` on branch `prototype/native-webview`, then-directory `prototype/native-webview/`. The app now lives in `Sources/T3HUD/`.

Question: can the existing T3 UI authenticate and operate inside a persistent native HUD panel?

Result: the native app builds, T3 pairing succeeds, the existing thread list and conversation load, and the user sent a prompt from the HUD and received a reply. This validates hosting the existing T3 UI for the core workflow. Keep the implementation as the starting point for the MVP.

Remaining work: remember the connection endpoint without credentials, add dragging and remembered icon placement, package normal app launch, and verify global hotkeys, focus, retained drafts, fullscreen, and disconnect/reconnect behavior. Overall verification remains INCONCLUSIVE until those window and lifecycle checks are completed.
