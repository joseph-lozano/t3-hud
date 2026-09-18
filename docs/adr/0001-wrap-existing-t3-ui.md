# Wrap the existing T3 UI in a separate app

The personal macOS MVP will host T3 Code's existing UI in a separate HUD wrapper. Checking threads and sending prompts does not yet justify maintaining a custom interface or a fork of T3 Code. T3 owns connection handling, authentication, threads, and client state; the wrapper owns the floating icon, panel, and hotkey. This keeps the wrapper small but makes its behavior dependent on the existing T3 web UI, whose native webview compatibility and pairing flow need verification.
