import AppKit

/// A compact notification that opens the thread without taking focus first.
final class NotificationToast: NSButton {
    override var isOpaque: Bool { false }
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }

    override func draw(_ dirtyRect: NSRect) {
        NSColor.clear.setFill()
        bounds.fill(using: .copy)
        let card = NSBezierPath(roundedRect: bounds.insetBy(dx: 1, dy: 1), xRadius: 12, yRadius: 12)
        NSColor(calibratedWhite: isHighlighted ? 0.18 : 0.10, alpha: 0.98).setFill()
        card.fill()
        NSColor.white.withAlphaComponent(0.12).setStroke()
        card.lineWidth = 1
        card.stroke()

        let paragraph = NSMutableParagraphStyle()
        paragraph.lineBreakMode = .byTruncatingTail
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 13, weight: .semibold),
            .foregroundColor: NSColor.white,
            .paragraphStyle: paragraph
        ]
        (title as NSString).draw(in: NSRect(x: 16, y: bounds.midY - 9, width: bounds.width - 32, height: 18), withAttributes: attributes)
    }
}
