# Prototype verdict

Verification: INCONCLUSIVE

The native integration is viable enough for an authenticated trial, but the main question is not yet settled.

## Observed

- `./prototype/native-webview/run` compiled and launched using the installed Swift compiler.
- Carbon returned success registering Command+Option+H.
- The real T3 browser UI at the existing local server rendered its pairing form inside WKWebView. Native WebKit could load the app's JavaScript and display the form.
- Typing a disposable marker into the pairing form worked. Escape left the panel and field value intact. No form was submitted.
- T3's actual Connections UI showed Network access disabled and no pairing-link controls.

## Not established

- Pairing/authentication, shared threads, and sending prompts.
- Actual global shortcut dispatch while another app has focus.
- Icon hide/show retention, focus return, fullscreen, and multiple displays.
- Draft persistence or selection behavior in authenticated T3.

The coding session itself runs on this T3 backend. Network configuration was not changed because that can restart it. No prompts or external messages were sent. The next experiment requires a T3 pairing link supplied directly to the prototype and the manual steps in README.md.

## Reproduction

Run `./prototype/native-webview/run` with T3 available locally. Observe the pairing form and footer. An unauthenticated pairing screen is the expected negative control: it must not be reported as connected to shared threads.

## Independent review

A separate verifier compiled and typechecked the native source without diagnostics. It found no decisive defect in the narrow prototype scope, but independently returned INCONCLUSIVE because authentication, thread retention, hotkey dispatch, and focus behavior lack runtime proof.

Source fingerprint, SHA-256: `e408630c462bbdcd6b429d1edf5be12091c6c802c580ecb71c87f6d92026da81`.

Captured UI evidence: [pairing screen](evidence/pairing.png).
