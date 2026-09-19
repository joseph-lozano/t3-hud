# Notification API availability check

Checked 2026-09-18. Research probe only, no product changes or permission requests.

A disposable native WKWebView loaded https://app.t3.codes with a fresh, nonpersistent data store. It uses the HUD's web engine and standard configuration but does not inherit its signed-in session or permission state. Probe source and raw result are in `.verification/notification-api/main.swift` and `result.json`.

| API / state | Observed |
| --- | --- |
| `Notification` | function |
| `Notification.requestPermission` | function, not called |
| `Notification.permission` | default in isolated store |
| `navigator.serviceWorker` | present |
| `PushManager` | undefined |
| `navigator.setAppBadge` / `clearAppBadge` | undefined |
| `MutationObserver` | function |
| `window.desktopBridge` | undefined |
| `window.webkit.messageHandlers` | absent, no native handler registered in probe |
| Secure context | true |
| Hidden, never-shown probe | visibilityState hidden, hasFocus false |
| Favicon | https://app.t3.codes/favicon.ico |

The actual deployed entry asset was index-CbWpF9pH.js; its main-D-4ehMuj.js dependency contains Notification.permission gating, construction of silent Notifications with environment/thread tags, click handlers, and setNotificationBadge/favicon code. Public bundles were fetched read-only and preserved beside the probe. Sources: [deployed entry](https://app.t3.codes/assets/index-CbWpF9pH.js), [deployed main bundle](https://app.t3.codes/assets/main-D-4ehMuj.js).

Conclusion: Notification exists, so missing API is not established. Existence does not prove permission prompts or delivery work in this embedded context. Next proof would need an explicitly authorized permission interaction and actual notification construction/delivery in the isolated app. Showing then hiding a real HUD window must also be tested; the never-shown probe establishes only its initial hidden state. No signed-in thread events, notification delivery, native badge bridge, or live focus transitions were tested. The probe exited after inspection.

## Follow-up: permission request

A separate disposable macOS app, `local.t3hud.notificationprobe20260918`, loaded the actual HTTPS T3 Connect welcome page in WKWebView with a fresh default persistent data store. Its injected test button called the unmodified `Notification.requestPermission()` from a real UI click. The bridge recorded `navigator.userActivation.isActive === true` and initial permission `default`.

Result: the promise resolved to `denied`, and `Notification.permission` became `denied`. No permission dialog appeared during the observed request. Notification construction/delivery was not attempted without permission. This demonstrates that API presence alone is insufficient in the tested stock WKWebView configuration. It does not establish universal behavior across macOS versions or app configurations; the disposable app was ad-hoc signed and did not implement any custom notification integration.

Evidence: `.verification/notification-permission/events.jsonl`, `permission-result.png`, and `main.swift`. The probe was quit after inspection. The installed HUD, its data store, and T3 notification settings were not changed. No T3 prompts were sent. Next step, if approved, is the isolated native notification compatibility adapter experiment; this result does not authorize or implement it.
