# Verification features

Use `.agents/skills/verifying-t3-hud/SKILL.md` for isolated launch, doctor, and cleanup.

| Feature | Action | Expected observation |
| --- | --- | --- |
| Client only | Launch the normal build with a legacy `connectionURL` preference set; open the T3 menu | Loads `https://app.t3.codes`; no connection bar or URL field; `connectionURL` is removed; T3 → Reload T3 (Cmd+R) reloads the page |
| Verification override | Launch the run-owned bundle from `session.py start` | Loads the fixture from `verificationURL`; the override is ignored outside `local.t3hud.verify.*` bundles |
| Icon placement | Drag icon at least 100 points, click it to toggle, quit and reopen | Drag moves the panel without toggling; click toggles; icon returns to saved position |
| Draft retention | Type a marker, toggle twice, record Document ID | Same document ID and draft; focus can type in webview |
| Global shortcut and focus | User presses Cmd+Option+H with host active, types into HUD, hides, types into host | HUD toggles without activating unrelated apps; expected input reaches each view |
| Fullscreen | Enter fullscreen in disposable host, click floating icon and use hotkey | Icon and panel visible over host; host remains fullscreen |
| Reconnect | Mark fixture offline then online; repeat with launch while offline | Informational disconnect within eight seconds, automatic recovery; already-loaded document and draft retained |
| Normal launch | Build/install, launch `.app` through Launch Services, launch again | A single HUD process, correct app/menu names, existing pairing retained |
| Working comet | Start a thread, hide HUD, then let it finish | Gold comet orbits in 2.6 seconds while working and stops after completion; icon remains clickable and draggable |
| Concurrent activity | Leave one thread working while another completes; repeat across environments and with collapsed sidebar | Comet continues while any observed thread works; red notification count can coexist at the top right |
| Activity lifecycle | Reload, disconnect/reconnect, interrupt work, or reach an approval/input wait | No stale animation after connection close or reload; waiting threads alone do not animate; reconnect restores received working state |
| Reduce Motion | Toggle macOS Reduce Motion during work | Steady gold ring when enabled; comet resumes when disabled |

The comet build awaits the user's live T3 and native UI check. `node --test Tests/Bridge/activity.test.cjs` covers the passive protocol observer with controlled messages; those checks do not establish live compatibility or animation appearance.

The fixture checks wrapper behavior, not T3's internal WebSocket implementation. Multi-monitor physical checks require a second display. Global shortcuts require a physical user keypress with the current Computer Use driver.
