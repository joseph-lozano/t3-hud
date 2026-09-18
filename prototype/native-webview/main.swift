// THROWAWAY PROTOTYPE: real T3 UI inside a retained native HUD webview.
import AppKit
import WebKit
import Carbon

final class Panel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
    override func cancelOperation(_ sender: Any?) {} // Escape belongs to T3, not dismissal.
}

final class Prototype: NSObject, NSApplicationDelegate, WKNavigationDelegate, WKUIDelegate {
    var panel: Panel!
    var icon: NSPanel!
    var web: WKWebView!
    var address: NSTextField!
    var status: NSTextField!
    var item: NSStatusItem!
    var hotkey: EventHotKeyRef?
    var handler: EventHandlerRef?
    var loads = 0
    var toggles = 0
    var shortcut = "unregistered"
    var navigation = "idle"

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        let menu = NSMenu()
        menu.addItem(withTitle: "Toggle T3 HUD", action: #selector(toggle), keyEquivalent: "")
        menu.addItem(withTitle: "Quit prototype", action: #selector(quit), keyEquivalent: "q")
        for entry in menu.items { entry.target = self }
        item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        item.button?.title = "T3 P"
        item.menu = menu
        let edit = NSMenu(title: "Edit")
        edit.addItem(withTitle: "Copy", action: #selector(NSText.copy(_:)), keyEquivalent: "c")
        edit.addItem(withTitle: "Paste", action: #selector(NSText.paste(_:)), keyEquivalent: "v")
        edit.addItem(withTitle: "Cut", action: #selector(NSText.cut(_:)), keyEquivalent: "x")
        edit.addItem(withTitle: "Select All", action: #selector(NSText.selectAll(_:)), keyEquivalent: "a")
        let main = NSMenu(); let editItem = NSMenuItem(); editItem.submenu = edit; main.addItem(editItem)
        NSApp.mainMenu = main

        panel = Panel(contentRect: NSRect(x: 108, y: 160, width: 940, height: 650), styleMask: [.borderless, .resizable, .nonactivatingPanel], backing: .buffered, defer: false)
        panel.title = "T3 HUD Prototype"
        panel.minSize = NSSize(width: 640, height: 430)
        panel.level = .statusBar
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.hidesOnDeactivate = false
        panel.isReleasedWhenClosed = false
        panel.hasShadow = true
        let root = NSView(); panel.contentView = root
        let configuration = WKWebViewConfiguration()
        configuration.websiteDataStore = .default()
        web = WKWebView(frame: .zero, configuration: configuration)
        web.navigationDelegate = self; web.uiDelegate = self
        address = NSTextField(string: "http://127.0.0.1:3773")
        address.placeholderString = "T3 URL or pairing link"
        address.target = self; address.action = #selector(connect)
        let go = NSButton(title: "Load", target: self, action: #selector(connect))
        let reload = NSButton(title: "Reload", target: self, action: #selector(refresh))
        let top = NSStackView(views: [NSTextField(labelWithString: "PROTOTYPE"), address, go, reload])
        top.spacing = 8
        status = NSTextField(labelWithString: "")
        status.font = .monospacedSystemFont(ofSize: 10, weight: .regular)
        for view in [top, web!, status!] { view.translatesAutoresizingMaskIntoConstraints = false; root.addSubview(view) }
        NSLayoutConstraint.activate([
            top.leadingAnchor.constraint(equalTo: root.leadingAnchor, constant: 12), top.trailingAnchor.constraint(equalTo: root.trailingAnchor, constant: -12),
            top.topAnchor.constraint(equalTo: root.topAnchor, constant: 10), top.heightAnchor.constraint(equalToConstant: 28),
            web.topAnchor.constraint(equalTo: top.bottomAnchor, constant: 8), web.leadingAnchor.constraint(equalTo: root.leadingAnchor), web.trailingAnchor.constraint(equalTo: root.trailingAnchor),
            web.bottomAnchor.constraint(equalTo: status.topAnchor, constant: -6),
            status.leadingAnchor.constraint(equalTo: root.leadingAnchor, constant: 12), status.trailingAnchor.constraint(equalTo: root.trailingAnchor, constant: -12),
            status.bottomAnchor.constraint(equalTo: root.bottomAnchor, constant: -8)
        ])
        let screen = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1440, height: 900)
        icon = NSPanel(contentRect: NSRect(x: screen.minX + 32, y: screen.minY + 180, width: 64, height: 64), styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
        icon.level = .statusBar; icon.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        icon.hidesOnDeactivate = false
        let button = NSButton(title: "T3", target: self, action: #selector(toggle))
        button.toolTip = "Toggle T3 HUD prototype (Command Option H)"
        button.font = .systemFont(ofSize: 20, weight: .bold)
        icon.contentView = button; icon.orderFrontRegardless()
        position()
        var event = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        InstallEventHandler(GetApplicationEventTarget(), { _, _, context in
            guard let context else { return noErr }
            Unmanaged<Prototype>.fromOpaque(context).takeUnretainedValue().toggle()
            return noErr
        }, 1, &event, Unmanaged.passUnretained(self).toOpaque(), &handler)
        let result = RegisterEventHotKey(UInt32(kVK_ANSI_H), UInt32(cmdKey | optionKey), EventHotKeyID(signature: 0x54334850, id: 1), GetApplicationEventTarget(), 0, &hotkey)
        shortcut = result == noErr ? "Cmd+Opt+H registered" : "hotkey error \(result); use icon"
        connect(); toggle()
    }
    func position() {
        let screen = NSScreen.screens.first { $0.frame.contains(NSPoint(x: icon.frame.midX, y: icon.frame.midY)) }?.visibleFrame ?? NSScreen.main!.visibleFrame
        let size = panel.frame.size
        var x = icon.frame.maxX + 12
        if x + size.width > screen.maxX - 12 { x = icon.frame.minX - 12 - size.width }
        x = max(screen.minX + 12, min(x, screen.maxX - size.width - 12))
        let y = max(screen.minY + 12, min(icon.frame.maxY - size.height, screen.maxY - size.height - 12))
        panel.setFrameOrigin(NSPoint(x: x, y: y))
    }
    @objc func toggle() {
        toggles += 1
        if panel.isVisible { panel.orderOut(nil) }
        else { position(); panel.makeKeyAndOrderFront(nil); panel.makeFirstResponder(web) }
        report()
    }
    @objc func connect() {
        guard let url = URL(string: address.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)), ["http", "https"].contains(url.scheme?.lowercased() ?? ""), url.host != nil else {
            navigation = "Enter an HTTP(S) T3 URL"; report(); return
        }
        web.load(URLRequest(url: url))
        // Do not retain pairing credentials in the native address field.
        var safe = URLComponents(url: url, resolvingAgainstBaseURL: false)
        safe?.fragment = nil; safe?.query = nil; safe?.user = nil; safe?.password = nil
        address.stringValue = safe?.string ?? ""
    }
    @objc func refresh() { web.reload() }
    @objc func quit() { NSApp.terminate(nil) }
    func report() {
        let value = "\(shortcut) | visible=\(panel.isVisible) | toggles=\(toggles) | loads=\(loads) | \(navigation)"
        status.stringValue = value
        print(value); fflush(stdout)
    }
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) { self.navigation = "loading"; report() }
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) { loads += 1; self.navigation = "page loaded (not proof of authentication)"; report() }
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) { self.navigation = "Disconnected: T3 unavailable (\((error as NSError).code))"; report() }
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) { self.navigation = "Navigation failed (\((error as NSError).code))"; report() }
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        if navigationAction.targetFrame == nil { webView.load(navigationAction.request) }
        return nil
    }
}
let app = NSApplication.shared
let prototype = Prototype()
app.delegate = prototype
app.run()
