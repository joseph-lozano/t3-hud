import AppKit
import WebKit
import Carbon
import T3HUDCore

final class HUDPanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
    override func cancelOperation(_ sender: Any?) {} // Escape remains available to T3.
}

final class HUD: NSObject, NSApplicationDelegate, WKNavigationDelegate, WKUIDelegate, NSWindowDelegate {
    private var panel: HUDPanel!
    private var icon: NSPanel!
    private var web: WKWebView!
    private var address: NSTextField!
    private var status: NSTextField!
    private var disconnected: NSView!
    private var item: NSStatusItem!
    private var hotkey: EventHotKeyRef?
    private var handler: EventHandlerRef?
    private let preferences = UserDefaults.standard
    private let monitor = ConnectionMonitor()
    private var connection: Connection?
    private var failedNavigation = false
    private var shortcutAvailable = false
    private var reachable: Bool?
    private var statusMessage = "Connecting…"

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        // App launches and Finder opens must not create competing hotkeys or views.
        if let id = Bundle.main.bundleIdentifier,
           let other = NSRunningApplication.runningApplications(withBundleIdentifier: id).first(where: { $0.processIdentifier != ProcessInfo.processInfo.processIdentifier }) {
            other.activate(options: [.activateIgnoringOtherApps])
            NSApp.terminate(nil)
            return
        }
        makeMenus()
        makePanel()
        makeIcon()
        restoreIcon()
        registerShortcut()
        NotificationCenter.default.addObserver(self, selector: #selector(displaysChanged), name: NSApplication.didChangeScreenParametersNotification, object: nil)
        connect()
        show()
    }

    private func makeMenus() {
        let menu = NSMenu()
        menu.addItem(withTitle: "Show / Hide T3 HUD", action: #selector(toggle), keyEquivalent: "")
        menu.addItem(.separator())
        menu.addItem(withTitle: "Quit T3 HUD", action: #selector(quit), keyEquivalent: "q")
        menu.items.forEach { $0.target = self }
        item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        item.button?.title = "T3"
        item.button?.toolTip = "T3 HUD"
        item.menu = menu

        let main = NSMenu()
        let appItem = NSMenuItem(); appItem.submenu = menu.copy() as? NSMenu; main.addItem(appItem)
        let edit = NSMenu(title: "Edit")
        edit.addItem(withTitle: "Undo", action: Selector(("undo:")), keyEquivalent: "z")
        let redo = edit.addItem(withTitle: "Redo", action: Selector(("redo:")), keyEquivalent: "z")
        redo.keyEquivalentModifierMask = [.command, .shift]
        edit.addItem(.separator())
        edit.addItem(withTitle: "Copy", action: #selector(NSText.copy(_:)), keyEquivalent: "c")
        edit.addItem(withTitle: "Paste", action: #selector(NSText.paste(_:)), keyEquivalent: "v")
        edit.addItem(withTitle: "Cut", action: #selector(NSText.cut(_:)), keyEquivalent: "x")
        edit.addItem(withTitle: "Select All", action: #selector(NSText.selectAll(_:)), keyEquivalent: "a")
        let editItem = NSMenuItem(); editItem.submenu = edit; main.addItem(editItem)
        NSApp.mainMenu = main
    }

    private func configure(_ window: NSPanel) {
        window.level = .statusBar
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .canJoinAllApplications]
        window.hidesOnDeactivate = false
        window.isReleasedWhenClosed = false
        window.hasShadow = true
    }

    private func makePanel() {
        panel = HUDPanel(contentRect: NSRect(x: 108, y: 160, width: 940, height: 650),
                         styleMask: [.borderless, .resizable, .nonactivatingPanel], backing: .buffered, defer: false)
        panel.title = "T3 HUD"
        panel.minSize = NSSize(width: 640, height: 430)
        panel.delegate = self
        configure(panel)
        let root = NSView(); panel.contentView = root
        let configuration = WKWebViewConfiguration()
        configuration.websiteDataStore = .default()
        web = WKWebView(frame: .zero, configuration: configuration)
        web.navigationDelegate = self; web.uiDelegate = self
        address = NSTextField(string: preferences.string(forKey: "connectionURL") ?? "http://127.0.0.1:3773")
        address.placeholderString = "T3 server or pairing URL"
        address.setAccessibilityLabel("T3 connection URL")
        address.target = self; address.action = #selector(connect)
        let go = NSButton(title: "Connect", target: self, action: #selector(connect))
        let reload = NSButton(title: "Reload", target: self, action: #selector(refresh))
        let top = NSStackView(views: [address, go, reload]); top.spacing = 8
        status = NSTextField(labelWithString: "Connecting…")
        status.font = .systemFont(ofSize: 11)
        status.textColor = .secondaryLabelColor
        disconnected = NSView()
        disconnected.wantsLayer = true
        disconnected.layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor
        disconnected.isHidden = true
        let title = NSTextField(labelWithString: "T3 is disconnected")
        title.font = .systemFont(ofSize: 22, weight: .semibold)
        let detail = NSTextField(wrappingLabelWithString: "Waiting for your T3 server. This view will reconnect when it is available.")
        detail.alignment = .center
        let message = NSStackView(views: [title, detail]); message.orientation = .vertical; message.spacing = 12
        message.translatesAutoresizingMaskIntoConstraints = false
        disconnected.addSubview(message)
        for view in [top, web!, status!, disconnected!] {
            view.translatesAutoresizingMaskIntoConstraints = false
            root.addSubview(view)
        }
        NSLayoutConstraint.activate([
            top.leadingAnchor.constraint(equalTo: root.leadingAnchor, constant: 12),
            top.trailingAnchor.constraint(equalTo: root.trailingAnchor, constant: -12),
            top.topAnchor.constraint(equalTo: root.topAnchor, constant: 10), top.heightAnchor.constraint(equalToConstant: 28),
            web.topAnchor.constraint(equalTo: top.bottomAnchor, constant: 8),
            web.leadingAnchor.constraint(equalTo: root.leadingAnchor), web.trailingAnchor.constraint(equalTo: root.trailingAnchor),
            web.bottomAnchor.constraint(equalTo: status.topAnchor, constant: -6),
            status.leadingAnchor.constraint(equalTo: root.leadingAnchor, constant: 12),
            status.trailingAnchor.constraint(equalTo: root.trailingAnchor, constant: -12),
            status.bottomAnchor.constraint(equalTo: root.bottomAnchor, constant: -8),
            disconnected.leadingAnchor.constraint(equalTo: web.leadingAnchor), disconnected.trailingAnchor.constraint(equalTo: web.trailingAnchor),
            disconnected.topAnchor.constraint(equalTo: web.topAnchor), disconnected.bottomAnchor.constraint(equalTo: web.bottomAnchor),
            message.centerXAnchor.constraint(equalTo: disconnected.centerXAnchor), message.centerYAnchor.constraint(equalTo: disconnected.centerYAnchor),
            message.widthAnchor.constraint(lessThanOrEqualToConstant: 440),
            message.widthAnchor.constraint(lessThanOrEqualTo: disconnected.widthAnchor, constant: -40)
        ])
    }

    private func makeIcon() {
        icon = NSPanel(contentRect: NSRect(x: 32, y: 180, width: 64, height: 64),
                       styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
        icon.title = "T3 HUD Icon"
        configure(icon)
        let button = FloatingIcon(title: "T3", target: nil, action: nil)
        button.toolTip = "Click to toggle T3 HUD. Drag to move. ⌘⌥H"
        button.setAccessibilityLabel("Toggle T3 HUD")
        button.font = .systemFont(ofSize: 20, weight: .bold)
        button.onToggle = { [weak self] in self?.toggle() }
        button.onMove = { [weak self] finished in
            guard let self else { return }
            if finished { self.saveIcon() }
            self.positionPanel()
        }
        icon.contentView = button
        icon.orderFrontRegardless()
    }

    private func screenID(_ screen: NSScreen) -> UInt32 {
        (screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber)?.uint32Value ?? 0
    }

    private func iconScreen() -> NSScreen? {
        let center = CGPoint(x: icon.frame.midX, y: icon.frame.midY)
        if let screen = NSScreen.screens.first(where: { $0.frame.contains(center) }) { return screen }
        // A drag can finish in the gap between differently sized displays.
        return NSScreen.screens.min { left, right in
            func distance(_ rect: CGRect) -> CGFloat {
                let x = max(rect.minX, min(center.x, rect.maxX))
                let y = max(rect.minY, min(center.y, rect.maxY))
                return hypot(center.x - x, center.y - y)
            }
            return distance(left.visibleFrame) < distance(right.visibleFrame)
        }
    }

    private func restoreIcon() {
        guard let fallback = NSScreen.screens.first else { return }
        let saved = preferences.data(forKey: "iconPlacement").flatMap { try? JSONDecoder().decode(IconPlacement.self, from: $0) }
        let screen = saved.flatMap { placement in NSScreen.screens.first { screenID($0) == placement.screenID } } ?? fallback
        let frame = screen.visibleFrame
        let origin = saved?.restoredOrigin(in: frame) ?? IconPlacement.clamped(CGPoint(x: frame.minX + 32, y: frame.minY + 180), in: frame)
        icon.setFrameOrigin(origin)
        positionPanel()
    }

    private func saveIcon() {
        guard let screen = iconScreen() else { return }
        let origin = IconPlacement.clamped(icon.frame.origin, in: screen.visibleFrame)
        icon.setFrameOrigin(origin)
        let placement = IconPlacement(screenID: screenID(screen), origin: origin, screen: screen.visibleFrame)
        if let data = try? JSONEncoder().encode(placement) { preferences.set(data, forKey: "iconPlacement") }
    }

    private func positionPanel() {
        guard let screen = iconScreen() else { return }
        panel.minSize = NSSize(width: min(640, max(1, screen.visibleFrame.width - 24)),
                               height: min(430, max(1, screen.visibleFrame.height - 24)))
        let frame = IconPlacement.panelFrame(icon: icon.frame, size: panel.frame.size, screen: screen.visibleFrame)
        panel.setFrame(frame, display: true)
    }

    @objc private func displaysChanged() { restoreIcon() }
    func windowDidEndLiveResize(_ notification: Notification) { positionPanel() }

    private func registerShortcut() {
        var event = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        let installed = InstallEventHandler(GetApplicationEventTarget(), { _, _, context in
            guard let context else { return noErr }
            Unmanaged<HUD>.fromOpaque(context).takeUnretainedValue().toggle()
            return noErr
        }, 1, &event, Unmanaged.passUnretained(self).toOpaque(), &handler)
        if installed == noErr {
            shortcutAvailable = RegisterEventHotKey(UInt32(kVK_ANSI_H), UInt32(cmdKey | optionKey),
                EventHotKeyID(signature: 0x54334850, id: 1), GetApplicationEventTarget(), 0, &hotkey) == noErr
        }
        updateStatus()
    }

    private func show() {
        positionPanel()
        panel.makeKeyAndOrderFront(nil)
        panel.makeFirstResponder(disconnected.isHidden ? web : address)
    }

    @objc private func toggle() {
        if panel.isVisible { panel.orderOut(nil) } else { show() }
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        show()
        return true
    }

    @objc private func connect() {
        guard let next = Connection(address.stringValue) else {
            statusMessage = "Enter an HTTP or HTTPS URL without a username or password."
            updateStatus(); return
        }
        connection = next
        preferences.set(next.savedURL.absoluteString, forKey: "connectionURL")
        address.stringValue = next.savedURL.absoluteString
        reachable = nil
        failedNavigation = false
        disconnected.isHidden = true
        statusMessage = "Connecting…"; updateStatus()
        web.load(URLRequest(url: next.requestURL))
        monitor.start(url: next.savedURL) { [weak self] online in self?.reachabilityChanged(online) }
    }

    private func reachabilityChanged(_ online: Bool) {
        let becameUnavailable = !online && reachable != false
        reachable = online
        if becameUnavailable && panel.isKeyWindow { panel.makeFirstResponder(address) }
        disconnected.isHidden = online
        statusMessage = online ? "Server reachable" : "Disconnected · waiting for T3"
        updateStatus()
        if online && failedNavigation, let connection {
            failedNavigation = false
            // Pairing credentials are used only for the initial explicit connection.
            web.load(URLRequest(url: connection.savedURL))
        }
        // A loaded T3 document owns WebSocket reconnection. Keep its drafts intact.
    }

    @objc private func refresh() {
        guard let connection else { return }
        failedNavigation = false
        web.load(URLRequest(url: connection.savedURL))
    }

    @objc private func quit() { NSApp.terminate(nil) }

    func applicationWillTerminate(_ notification: Notification) {
        monitor.stop()
        if let hotkey { UnregisterEventHotKey(hotkey) }
        if let handler { RemoveEventHandler(handler) }
        NotificationCenter.default.removeObserver(self)
    }

    private func updateStatus() {
        let shortcut = shortcutAvailable ? "⌘⌥H" : "Shortcut unavailable; use the floating icon"
        status.stringValue = "\(statusMessage)  ·  \(shortcut)"
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        failedNavigation = false
        if reachable != false { disconnected.isHidden = true }
    }

    func webView(_ webView: WKWebView, decidePolicyFor response: WKNavigationResponse,
                 decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
        if response.isForMainFrame, let http = response.response as? HTTPURLResponse, http.statusCode >= 500 {
            failedNavigation = true
            disconnected.isHidden = false
            statusMessage = "Disconnected · waiting for T3"
            updateStatus()
            decisionHandler(.cancel)
        } else { decisionHandler(.allow) }
    }

    private func navigationFailed(_ error: Error) {
        guard (error as NSError).code != NSURLErrorCancelled else { return }
        failedNavigation = true
        disconnected.isHidden = false
        statusMessage = "Disconnected · waiting for T3"
        updateStatus()
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) { navigationFailed(error) }
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) { navigationFailed(error) }
    func webViewWebContentProcessDidTerminate(_ webView: WKWebView) { refresh() }
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration,
                 for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        if navigationAction.targetFrame == nil, let url = navigationAction.request.url {
            // External pages should not replace the user's thread in the HUD.
            NSWorkspace.shared.open(url)
        }
        return nil
    }
}

let app = NSApplication.shared
let hud = HUD()
app.delegate = hud
app.run()
