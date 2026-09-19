# Verification features

Use `.agents/skills/verifying-t3-hud/SKILL.md` for isolated launch, doctor, and cleanup.

| Feature | Action | Expected observation |
| --- | --- | --- |
| Connection bar | Launch, reveal with T3 → Show Connection Bar or Cmd+L, toggle it again | Hidden at launch; revealing shows saved address; hiding preserves current document and draft |
| Connection persistence | Reveal the connection bar, enter the fixture URL with `/pair#token=DISPOSABLE_MARKER`, Connect, quit and reopen the app | Bar remains hidden on reopen; revealing it shows the fixture root; no marker in saved `connectionURL`; fixture loads |
| Icon placement | Drag icon at least 100 points, click it to toggle, quit and reopen | Drag moves the panel without toggling; click toggles; icon returns to saved position |
| Draft retention | Type a marker, toggle twice, record Document ID | Same document ID and draft; focus can type in webview |
| Global shortcut and focus | User presses Cmd+Option+H with host active, types into HUD, hides, types into host | HUD toggles without activating unrelated apps; expected input reaches each view |
| Fullscreen | Enter fullscreen in disposable host, click floating icon and use hotkey | Icon and panel visible over host; host remains fullscreen |
| Reconnect | Mark fixture offline then online; repeat with launch while offline | Informational disconnect within eight seconds, automatic recovery; already-loaded document and draft retained |
| Normal launch | Build/install, launch `.app` through Launch Services, launch again | A single HUD process, correct app/menu names, existing pairing retained |

The fixture checks wrapper behavior, not T3's internal WebSocket implementation. Multi-monitor physical checks require a second display. Global shortcuts require a physical user keypress with the current Computer Use driver.
