import SwiftUI

extension Color {
    // ロゴ用カラー
    static let pikumeiGreenMain = Color(hex: "A0F0D0")   // 「ぴ」の薄緑
    static let pikumeiBlueMain = Color(hex: "A0D0F0")    // 「くめい」の薄青
    static let pikumeiOutlineGreen = Color(hex: "00C853") // 外側の太い緑縁
    
    // サブタイトル用（☆もので戦おう☆）
    static let pikumeiSubPurple = Color(hex: "6A5ACD")   // 紫の縁
    static let pikumeiSubBlueMain = Color(hex: "87CEFA")  // 中の青グラデ用
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b: UInt64
        switch hex.count {
        case 6: (r, g, b) = (int >> 16, int >> 8 & 0xFF, int & 0xFF)
        default: (r, g, b) = (1, 1, 1)
        }
        self.init(.sRGB, red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255, opacity: 1)
    }
}
