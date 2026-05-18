import Foundation
import UIKit

struct Recording: Identifiable, Equatable {
    let id = UUID()
    let fileURL: URL
    let createdAt: Date
    let duration: TimeInterval
    var title: String
    var isStarred: Bool = false
    var isShared: Bool = false
    var titleColorHex: String? = nil   // persisted per-recording title colour

    // Convenience: resolved UIColor (falls back to .label)
    var titleColor: UIColor {
        guard let hex = titleColorHex else { return .label }
        return UIColor(hex: hex) ?? .label
    }
}

// MARK: - UIColor hex helpers
extension UIColor {
    /// Init from a 6-digit hex string, e.g. "FF3B30"
    convenience init?(hex: String) {
        var hexSan = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        if hexSan.hasPrefix("#") { hexSan.removeFirst() }
        guard hexSan.count == 6, let rgb = UInt64(hexSan, radix: 16) else { return nil }
        self.init(
            red:   CGFloat((rgb >> 16) & 0xFF) / 255,
            green: CGFloat((rgb >>  8) & 0xFF) / 255,
            blue:  CGFloat( rgb        & 0xFF) / 255,
            alpha: 1
        )
    }

    /// Returns a 6-digit uppercase hex string, e.g. "FF3B30"
    var hexString: String {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        getRed(&r, green: &g, blue: &b, alpha: &a)
        return String(format: "%02X%02X%02X",
                      Int(r * 255), Int(g * 255), Int(b * 255))
    }
}
