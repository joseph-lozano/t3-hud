# UI verification fixtures

These fixtures support the public UI checks explicitly requested for the MVP: connection persistence, drag/placement, hotkeys/focus/fullscreen, and reconnect behavior. They never contact real T3 or send messages.

`fixture.py` serves a labelled input and unique document ID. `host.swift` provides a disposable fullscreen-capable native window. Launch them using the procedure in `.agents/skills/verifying-t3-hud/SKILL.md`, not against the user's browser profile. The session helper is `scripts/verification/session.py`.

No unit-test boundary was confirmed during this session; no unit-test target or passing unit suite is claimed. The required checks exercise the actual app UI and independent persisted preferences.
