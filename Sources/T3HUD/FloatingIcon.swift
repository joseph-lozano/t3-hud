import AppKit

final class FloatingIcon: NSButton {
    var badgeImage: NSImage? { didSet { needsDisplay = true } }
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
        let inset: CGFloat = pressed ? 4 : (hovered ? 1 : 2)
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
        badgeImage?.draw(in: NSRect(x: bounds.maxX - 20, y: 0, width: 20, height: 20),
                         from: .zero, operation: .sourceOver, fraction: 1, respectFlipped: true, hints: nil)
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
