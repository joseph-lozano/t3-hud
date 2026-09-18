# MVP verification

Status: VERIFIED for the requested changes: connection URL persistence, draggable remembered icon placement, normal app packaging, and hotkey/focus/fullscreen/reconnect behavior. Authenticated use of the installed build remains INCONCLUSIVE pending fresh T3 authorization; the current smoke check reaches T3’s pairing screen, not authenticated threads.

Run: `.verification/20260918-162402-8ff0b8b0`. Isolated fixture: `http://127.0.0.1:49802`. Bundle: `local.t3hud.verify.20260918-162402-8ff0b8b0`.

Evidence: run-local `evidence/` contains AX observations, screenshots, and SHA-256 fingerprints. `fingerprints.json` pins the initial build; `final-fingerprints.json` pins the refreshed build with `canJoinAllApplications`. Its executable was copied from the final `dist/T3 HUD.app`, preserving isolated bundle identity, then ad-hoc signed.

## Automated UI observations

- Launch Services opened the isolated `.app` and displayed the fixture's exact run ID.
- Entering `/pair#token=DISPOSABLE_MARKER` loaded the pairing URL while changing the visible connection field to the server root. `defaults read` confirmed saved `connectionURL` was `http://127.0.0.1:49802/`. Quit/relaunch restored that root and loaded the fixture.
- Typing `MVP_RETENTION_8ff0` into the fixture worked. Escape left the panel visible.
- Loaded-server failure showed the informational disconnected message; restoring the owned fixture recovered automatically with document `61f80336-7023-4431-93d0-82f0e850de97` and the same draft.
- Launching while fixture returned HTTP 503 showed disconnected UI. Restoring it loaded the fixture automatically without clicking Reload.
- Doctor returned READY online and failed nonzero with HTTP 503 offline, then returned READY after restoration.
- After refreshing the final build, the host entered fullscreen through its native green control. The HUD remained inspectable and could be hidden using its menu, then reopened via the floating icon's accessibility action. Document `eea2b0e7-30e4-405a-954a-cc55f7fe87c8` and draft stayed unchanged. Keyboard focus was reported in the webview after reopening.

App-specific screenshots do not prove cross-app fullscreen visibility. The Computer Use driver cannot generate a physical global shortcut; targeted key injection is not used as a substitute. Icon screenshots are window-local, so an absolute drag was not guessed.

## Human observations

The user reported “i think it all worked” for the requested hotkey, fullscreen, focus, and drag/click checks. They initially reported trouble typing, then clarified that typing worked and explicitly answered “No, the HUD gets keyboard input” when asked whether input remained in the app behind. These are human observations, distinct from automated key injection.

After the human drag, read-only preference capture showed `{x:3638, screenID:4, y:1377}`. An independent quit and Launch Services relaunch preserved those exact values, restored the valid fixture URL `/ee`, and displayed the prior draft. The user had edited the native field to an invalid port without connecting; verification corrected that field through the UI before quitting. No new connection was needed.

The driver provides window-cropped screenshots and AX text without window position, so visual restoration was checked by the user. After the automated quit/relaunch persistence check and cleanup, the exact captured preferences were restored to the isolated bundle and it was reopened without changing placement. Asked whether the icon returned to its previous position, the user explicitly confirmed: “Yes, same place.” The stopped fixture meant the panel showed its expected disconnected view during this final native placement check.

Evidence files `13-before-relaunch-prefs.txt`, `14-after-relaunch-prefs.txt`, corresponding AX/screenshot captures, and `15-restored-for-human-check.txt` record the automated parts. Preference persistence across quit/relaunch and the final human visual restoration check are separate observations.

## Installed production smoke check

The parent launched `~/Applications/T3 HUD.app` through Launch Services and entered the previously paired T3 LAN endpoint through its connection field. The installed app loaded T3’s pairing screen. It did not show authenticated threads, and no prompt was sent. The installed executable matched the built executable and passed strict code-signature verification, as recorded by the parent.

The existing bundle identifier `local.t3hud.prototype` and the default persistent WebKit data store are retained. That preserves the storage identity; it does not establish that T3 still accepts the stored session. The reason reauthorization is required has not been determined. There is no evidence here of a wrapper defect, and no evidence that server revocation caused it either.

Fresh pairing is required to complete the installed build’s authenticated smoke check. The user’s earlier prototype prompt established the original integration, but is not presented as a current authenticated roundtrip. This is an explicit limitation on operational readiness, rather than a failure of the separately verified persistence, window, packaging, or reconnect changes.

## Remaining scratch resources

The isolated HUD and bundled host were quit through their menus. The host was already out of fullscreen at cleanup. Owned standalone host PID 69865 was stopped after matching its exact command. `session.py cleanup` stopped the owned fixture and removed isolated preferences. Following the final visual confirmation, the reopened isolated HUD was quit through its menu and `session.py cleanup` removed the restored unique preferences again. Process checks found no remaining isolated HUD or either host. Run-owned app bundles, WebKit storage, screenshots, and evidence remain for inspection. The isolated verification accessed no real T3 credentials, server settings, or messages. The separate production smoke observed only the pairing screen; no credentials were inspected or messages sent.
