import SwiftUI

/// example-mobile-android colors.xml (DESIGN_TOKENS) ile birebir palet.
enum Theme {
    static let bgDark        = Color(hex: 0x0F172A)  // slate-900
    static let surface       = Color(hex: 0x1E293B)  // slate-800
    static let cardStroke    = Color(hex: 0x334155)  // slate-700
    static let primary       = Color(hex: 0x2563EB)  // blue-600
    static let blue400       = Color(hex: 0x60A5FA)
    static let accentCyan    = Color(hex: 0x22D3EE)
    static let textPrimary   = Color(hex: 0xF1F5F9)  // slate-100
    static let textSecondary = Color(hex: 0x94A3B8)  // slate-400
    static let successText   = Color(hex: 0x34D399)
    static let errorText     = Color(hex: 0xF87171)
    static let codeBg        = Color(hex: 0x020617)  // slate-950
    static let onPrimary     = Color.white
    static let successBg     = Color(hex: 0x10B981).opacity(0.13)
    static let errorBg       = Color(hex: 0xEF4444).opacity(0.13)
}

extension Color {
    init(hex: UInt32) {
        self.init(
            .sRGB,
            red:   Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue:  Double(hex & 0xFF) / 255,
            opacity: 1
        )
    }
}

/// Kod içinden lokalize string (Localizable.strings).
func L(_ key: String) -> String { NSLocalizedString(key, comment: "") }
func L(_ key: String, _ args: CVarArg...) -> String {
    String(format: NSLocalizedString(key, comment: ""), arguments: args)
}
