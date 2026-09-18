import AppKit

final class FloatingIcon: NSButton {
    var onToggle: (() -> Void)?
    var onMove: ((_ finished: Bool) -> Void)?

    override func mouseDown(with event: NSEvent) {
        guard let window else { return }
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
