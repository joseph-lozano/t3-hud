import Foundation
import CoreGraphics

public struct IconPlacement: Codable {
    public let screenID: UInt32
    public let x: Double
    public let y: Double

    public init(screenID: UInt32, origin: CGPoint, screen: CGRect) {
        self.screenID = screenID
        x = origin.x - screen.minX
        y = origin.y - screen.minY
    }

    public func restoredOrigin(in screen: CGRect) -> CGPoint {
        Self.clamped(CGPoint(x: screen.minX + x, y: screen.minY + y), in: screen)
    }

    public static func clamped(_ point: CGPoint, in screen: CGRect) -> CGPoint {
        CGPoint(x: max(screen.minX, min(point.x, screen.maxX - 64)),
                y: max(screen.minY, min(point.y, screen.maxY - 64)))
    }

    public static func panelFrame(icon: CGRect, size: CGSize, screen: CGRect) -> CGRect {
        let width = min(size.width, max(1, screen.width - 24))
        let height = min(size.height, max(1, screen.height - 24))
        let right = icon.maxX + 12
        let x = right + width <= screen.maxX - 12 ? right : icon.minX - 12 - width
        return CGRect(x: max(screen.minX + 12, min(x, screen.maxX - width - 12)),
                      y: max(screen.minY + 12, min(icon.maxY - height, screen.maxY - height - 12)),
                      width: width, height: height)
    }
}
