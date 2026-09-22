import AppKit

final class FloatingIcon: NSButton {
    var badgeImage: NSImage? { didSet { needsDisplay = true } }
    var isWorking = false {
        didSet {
            guard oldValue != isWorking else { return }
            updateAnimation()
        }
    }
    private var animationTimer: Timer?
    private var accessibilityObserver: NSObjectProtocol?
    private var animationStart = ProcessInfo.processInfo.systemUptime

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        if accessibilityObserver == nil {
            accessibilityObserver = NSWorkspace.shared.notificationCenter.addObserver(
                forName: NSWorkspace.accessibilityDisplayOptionsDidChangeNotification,
                object: nil, queue: .main
            ) { [weak self] _ in self?.updateAnimation() }
        }
        updateAnimation()
    }

    private func updateAnimation() {
        animationTimer?.invalidate()
        animationTimer = nil
        animationStart = ProcessInfo.processInfo.systemUptime
        if isWorking && window != nil && !NSWorkspace.shared.accessibilityDisplayShouldReduceMotion {
            let timer = Timer(timeInterval: 1.0 / 30, repeats: true) { [weak self] _ in
                self?.needsDisplay = true
            }
            RunLoop.main.add(timer, forMode: .common)
            animationTimer = timer
        }
        needsDisplay = true
    }

    deinit {
        animationTimer?.invalidate()
        if let accessibilityObserver {
            NSWorkspace.shared.notificationCenter.removeObserver(accessibilityObserver)
        }
    }
    private let mark = Bundle.main.url(forResource: "T3Mark", withExtension: "png").flatMap { NSImage(contentsOf: $0) }
    private var hoverTracking: NSTrackingArea?
    private var hovered = false { didSet { needsDisplay = true } }
    private var pressed = false { didSet { needsDisplay = true } }

    override var isOpaque: Bool { false }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        if let hoverTracking { removeTrackingArea(hoverTracking) }
        let tracking = NSTrackingArea(rect: .zero, options: [.mouseEnteredAndExited, .activeAlways, .inVisibleRect], owner: self)
        addTrackingArea(tracking)
        hoverTracking = tracking
    }

    override func mouseEntered(with event: NSEvent) { hovered = true }
    override func mouseExited(with event: NSEvent) { hovered = false }

    override func draw(_ dirtyRect: NSRect) {
        NSColor.clear.setFill()
        bounds.fill(using: .copy)
        let inset: CGFloat = isWorking ? (pressed ? 5 : 4) : (pressed ? 4 : (hovered ? 1 : 2))
        let tile = bounds.insetBy(dx: inset, dy: inset)
        NSGraphicsContext.saveGraphicsState()
        let shadow = NSShadow()
        shadow.shadowColor = NSColor.black.withAlphaComponent(hovered ? 0.4 : 0.28)
        shadow.shadowBlurRadius = hovered ? 5 : 3
        shadow.shadowOffset = NSSize(width: 0, height: -2)
        shadow.set()
        let circle = NSBezierPath(ovalIn: tile)
        NSColor.black.setFill()
        circle.fill()
        NSShadow().set()
        circle.addClip()
        if let mark {
            NSGraphicsContext.current?.imageInterpolation = .high
            mark.draw(in: tile, from: .zero, operation: .sourceOver, fraction: pressed ? 0.85 : 1, respectFlipped: true, hints: nil)
        } else {
            // Keeps a direct `swift run` usable without an app resource bundle.
            NSColor.black.setFill()
            circle.fill()
            let text = "T3" as NSString
            let attributes: [NSAttributedString.Key: Any] = [.font: NSFont.systemFont(ofSize: 23, weight: .heavy), .foregroundColor: NSColor.white]
            let size = text.size(withAttributes: attributes)
            text.draw(at: NSPoint(x: bounds.midX - size.width / 2, y: bounds.midY - size.height / 2), withAttributes: attributes)
        }
        NSGraphicsContext.restoreGraphicsState()
        NSColor.white.withAlphaComponent(hovered ? 0.28 : 0.16).setStroke()
        let rim = NSBezierPath(ovalIn: tile.insetBy(dx: 0.4, dy: 0.4))
        rim.lineWidth = 0.8
        rim.stroke()
        if isWorking { drawComet() }
        badgeImage?.draw(in: NSRect(x: bounds.maxX - 20, y: isFlipped ? bounds.minY : bounds.maxY - 20, width: 20, height: 20),
                         from: .zero, operation: .sourceOver, fraction: 1, respectFlipped: true, hints: nil)
    }

    private func drawComet() {
        // HSL 45°, 100%, 56%; matches the chosen 48-point preview.
        let gold = NSColor(srgbRed: 1, green: 0.78, blue: 0.12, alpha: 1)
        if NSWorkspace.shared.accessibilityDisplayShouldReduceMotion {
            gold.setStroke()
            let ring = NSBezierPath(ovalIn: bounds.insetBy(dx: 1.5, dy: 1.5))
            ring.lineWidth = 3
            ring.stroke()
            return
        }
        let phase = (ProcessInfo.processInfo.systemUptime - animationStart) / 2.6 * 2 * Double.pi
        let radius = min(bounds.width, bounds.height) / 2 - 1.5
        // One 140-degree tail. Only the ring moves; the mark and badge stay still.
        for step in 0..<70 {
            let fraction = Double(step) / 69
            let angle = phase + (220 + fraction * 140) * Double.pi / 180
            let next = angle + 2.3 * Double.pi / 180
            let highlight = max(0, (fraction - 0.78) / 0.22) * 0.6
            let color = gold.blended(withFraction: highlight, of: .white) ?? gold
            color.withAlphaComponent(fraction).setStroke()
            func point(_ a: Double) -> NSPoint {
                NSPoint(x: bounds.midX + radius * cos(a),
                        y: bounds.midY + radius * sin(a) * (isFlipped ? 1 : -1))
            }
            let segment = NSBezierPath()
            segment.move(to: point(angle))
            segment.line(to: point(next))
            segment.lineWidth = 3
            segment.stroke()
        }
    }

    var onToggle: (() -> Void)?
    var onMove: ((_ finished: Bool) -> Void)?

    override func mouseDown(with event: NSEvent) {
        guard let window else { return }
        pressed = true
        defer { pressed = false }
        let start = NSEvent.mouseLocation
        let origin = window.frame.origin
        var dragged = false
        while let next = window.nextEvent(matching: [.leftMouseDragged, .leftMouseUp]) {
            let point = NSEvent.mouseLocation
            if hypot(point.x - start.x, point.y - start.y) > 4 { dragged = true }
            if dragged {
                window.setFrameOrigin(NSPoint(x: origin.x + point.x - start.x,
                                              y: origin.y + point.y - start.y))
                onMove?(next.type == .leftMouseUp)
            }
            if next.type == .leftMouseUp {
                if !dragged { onToggle?() }
                break
            }
        }
    }

    override func accessibilityPerformPress() -> Bool {
        onToggle?()
        return true
    }
}
