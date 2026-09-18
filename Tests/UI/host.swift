import AppKit
final class Host: NSObject, NSApplicationDelegate {
    var window: NSWindow!
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        window = NSWindow(contentRect: NSRect(x: 200, y: 200, width: 800, height: 500), styleMask: [.titled, .closable, .resizable, .miniaturizable], backing: .buffered, defer: false)
        window.title = "HUD verification host"
        window.collectionBehavior = [.fullScreenPrimary]
        let text = NSTextView(frame: window.contentView!.bounds)
        text.autoresizingMask = [.width, .height]
        text.font = .systemFont(ofSize: 22)
        text.string = "Fullscreen and focus test host.\nUse the green window control to enter fullscreen.\nType here to check focus returns from the HUD."
        window.contentView = text
        let menu = NSMenu(); let root = NSMenuItem(); let appMenu = NSMenu()
        let quit = appMenu.addItem(withTitle: "Quit verification host", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"); quit.target = NSApp
        root.submenu = appMenu; menu.addItem(root); NSApp.mainMenu = menu
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}
let app = NSApplication.shared
let host = Host(); app.delegate = host; app.run()
