# Notification bridge experiment

The initial experiment used an injected browser Notification adapter and mirrored T3’s favicon badge without modifying the hosted UI. Its scratch snapshot remains on the local `prototype/notification-bridge` branch and is not part of the public main branch history.

The bridge is now integrated into the normal HUD. The user confirmed live completion notifications and the floating badge. Notifications display only the thread title, with an eight-second timeout restored after comparing five seconds. Alert permission is stored per origin. Popup click navigation has not received a separate live verification.

Local evidence remains in the ignored `.verification/` directory. No signed-in session, pairing credential, or verification log is included in the repository.
