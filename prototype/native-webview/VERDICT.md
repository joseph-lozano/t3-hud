# Prototype verdict

Verification: INCONCLUSIVE

Pairing succeeded with a user-supplied one-time link. The existing thread list and this conversation load inside the native HUD. The user successfully sent a prompt from the HUD. Global hotkey/focus behavior remains unverified.

## Observed

- `./prototype/native-webview/run` compiled and launched using the installed Swift compiler.
- Carbon returned success registering Command+Option+H.
- The real T3 browser UI at the existing local server rendered its pairing form inside WKWebView. Native WebKit could load the app's JavaScript and display the form.
- Typing a disposable marker into the pairing form worked. Escape left the panel and field value intact. No form was submitted.
- T3's actual Connections UI showed Network access disabled and no pairing-link controls.

## Not established

- Actual global shortcut dispatch while another app has focus.
- Icon hide/show retention, focus return, fullscreen, and multiple displays.
- Draft persistence or selection behavior in authenticated T3.

The coding session itself runs on this T3 backend. Network configuration was not changed because that can restart it. The agent sent no prompts or external messages. The user subsequently paired the prototype and sent a test prompt. Remaining experiments are the hide/show, focus, restart, and disconnection checks in README.md.

## Reproduction

Run `./prototype/native-webview/run` with T3 available locally. Observe the pairing form and footer. An unauthenticated pairing screen is the expected negative control: it must not be reported as connected to shared threads.

## Independent review

A separate verifier compiled and typechecked the native source without diagnostics. It found no decisive defect in the narrow prototype scope, but independently returned INCONCLUSIVE because authentication, thread retention, hotkey dispatch, and focus behavior lack runtime proof.

Source fingerprint, SHA-256: `e408630c462bbdcd6b429d1edf5be12091c6c802c580ecb71c87f6d92026da81`.

Captured UI evidence: [pairing screen](evidence/pairing.png).

## Authenticated follow-up

The user supplied a one-time pairing link after configuring network access. Loaded it directly in the native URL field without saving the credential to repository files. T3 exchanged the credential and displayed the existing thread list. Opening the existing HUD development thread loaded its conversation and focused the composer. No message was sent. The app remains open for user testing.

The prototype still defaults to the loopback endpoint at launch. Its paired session belongs to the supplied endpoint, so after restarting, load that same endpoint without the consumed token. Endpoint persistence is not implemented.

## User acceptance checkpoint

The user sent "test from the hud" through the authenticated prototype, and the assistant received and answered it in the existing conversation. The user then reported that it works well. This establishes a successful user-driven prompt round trip, not blanket verification of all window and lifecycle behavior.
