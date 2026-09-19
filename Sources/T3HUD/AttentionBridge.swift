import AppKit
import WebKit

// Experimental adapter for T3 browser notifications; T3 owns badge state.
final class AttentionBridge: NSObject, WKScriptMessageHandler {
    weak var web: WKWebView?
    weak var panel: NSPanel?
    weak var icon: NSPanel?
    var onBadge: ((NSImage?) -> Void)?
    var onOpen: (() -> Void)?
    var origin = ""
    var toast: NSPanel?
    var currentID: String?
    var timer: Timer?
    private let logURL: URL = {
        let root = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0].appendingPathComponent("T3 HUD")
        try? FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        return root.appendingPathComponent("notification-bridge.jsonl")
    }()
    func userScript(_ source: String) -> String {
        let permissions = UserDefaults.standard.dictionary(forKey: "hudAlertPermissions") ?? [:]
        guard let data = try? JSONSerialization.data(withJSONObject: permissions, options: [.sortedKeys]),
              let json = String(data: data, encoding: .utf8) else { return source }
        return source.replacingOccurrences(of: "/* HUD_PERMISSION */ 'default'", with: "(\(json)[location.origin] === true ? 'granted' : 'default')")
    }
    func record(_ entry: [String:Any]) {
        guard let data = try? JSONSerialization.data(withJSONObject:entry,options:[.sortedKeys]) else { return }
        if let size = (try? FileManager.default.attributesOfItem(atPath: logURL.path)[.size]) as? Int, size > 256_000 {
            try? Data().write(to: logURL)
        }
        if !FileManager.default.fileExists(atPath:logURL.path) { FileManager.default.createFile(atPath:logURL.path,contents:nil) }
        if let f=try? FileHandle(forWritingTo:logURL) { f.seekToEndOfFile();f.write(data);f.write(Data([10]));try? f.close() }
    }
    func userContentController(_ controller: WKUserContentController, didReceive message: WKScriptMessage) {
        guard message.frameInfo.isMainFrame, let frameURL=message.frameInfo.request.url,
              Self.origin(frameURL)==origin, let data=message.body as? [String:Any], let op=data["op"] as? String else { return }
        switch op {
        case "permission":
            guard let panel else { return }
            let alert=NSAlert(); alert.messageText="Enable HUD alerts?"
            alert.informativeText="T3 notifications will appear beside the floating T3 icon. This does not enable macOS Notification Center alerts. You can turn thread notifications off in T3 settings."
            alert.addButton(withTitle:"Enable HUD Alerts");alert.addButton(withTitle:"Not Now")
            alert.beginSheetModal(for:panel) { [weak self] result in
                let granted=result == .alertFirstButtonReturn
                if let origin = self?.origin, granted {
                    var permissions = UserDefaults.standard.dictionary(forKey: "hudAlertPermissions") ?? [:]
                    permissions[origin] = true
                    UserDefaults.standard.set(permissions, forKey: "hudAlertPermissions")
                }
                self?.web?.evaluateJavaScript("window.__t3HudBridge.permission('\(granted ? "granted" : "denied")')",completionHandler:nil)
                self?.record(["event":"permission","granted":granted])
            }
        case "notify":
            guard let id=data["id"] as? String, let title=data["title"] as? String, let body=data["body"] as? String, title.count<500,body.count<4000 else { return }
            record(["event":"notify","id":id,"panelVisible":panel?.isVisible ?? false])
            if panel?.isVisible == false { showToast(id:id,title:title,body:body) }
        case "close":
            if data["id"] as? String == currentID { hideToast() }
            record(["event":"close","id":data["id"] as? String ?? ""])
        case "badge":
            guard let value=data["image"] as? String,value.count<100_000 else { return }
            if value.isEmpty { onBadge?(nil); record(["event":"badge","present":false]);return }
            let prefix="data:image/png;base64,"
            guard value.hasPrefix(prefix),let bytes=Data(base64Encoded:String(value.dropFirst(prefix.count))),let image=NSImage(data:bytes),image.size.width<=128,image.size.height<=128 else { return }
            onBadge?(image);record(["event":"badge","present":true,"bytes":bytes.count])
        case "ready", "state":
            record(["event":op,"visible":data["visible"] ?? "", "focused":data["focused"] ?? false])
        default: break
        }
    }
    static func origin(_ url: URL) -> String { "\(url.scheme ?? "")://\(url.host ?? "")\(url.port.map { ":\($0)" } ?? "")" }
    func showToast(id:String,title:String,body:String) {
        hideToast();currentID=id
        let window=NSPanel(contentRect:NSRect(x:0,y:0,width:320,height:52),styleMask:[.borderless,.nonactivatingPanel],backing:.buffered,defer:false)
        window.title="T3 HUD Alert";window.level = .statusBar;window.hidesOnDeactivate=false
        window.collectionBehavior=[.canJoinAllSpaces,.fullScreenAuxiliary,.canJoinAllApplications]
        // T3 puts the thread title in the browser notification's body.
        let threadTitle = body.trimmingCharacters(in: .whitespacesAndNewlines)
        let label = threadTitle.isEmpty ? title : threadTitle
        let button=NotificationToast(title:label,target:self,action:#selector(clicked))
        button.toolTip = label
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = true
        button.setAccessibilityLabel("Open thread: \(label)");window.contentView=button
        if let icon {
            let screen = icon.screen?.visibleFrame ?? NSScreen.main?.visibleFrame ?? icon.frame
            let x = max(screen.minX, min(icon.frame.minX, screen.maxX - 320))
            let below = icon.frame.minY - 64
            let y = below >= screen.minY ? below : min(icon.frame.maxY + 12, screen.maxY - 52)
            window.setFrameOrigin(NSPoint(x:x,y:y))
        }
        toast=window;window.orderFrontRegardless()
        timer=Timer.scheduledTimer(withTimeInterval:8,repeats:false){[weak self] _ in self?.hideToast()}
        record(["event":"toast-shown","id":id])
    }
    @objc func clicked() {
        guard let id=currentID,let data=try? JSONSerialization.data(withJSONObject:[id]),let array=String(data:data,encoding:.utf8) else{return}
        hideToast()
        web?.evaluateJavaScript("window.__t3HudBridge.click(\(array)[0])") { [weak self] _, _ in self?.onOpen?() }
        record(["event":"notification-click","id":id])
    }
    func hideToast(){timer?.invalidate();toast?.orderOut(nil);toast=nil;currentID=nil}
}
