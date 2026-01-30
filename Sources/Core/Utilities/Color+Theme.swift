import SwiftUI

// MARK: - 主題色彩
extension Color {
    // 主色調 - 奶茶色系
    static let teaBrown = Color(hex: "#8B6F47")
    static let milkCream = Color(hex: "#F5E6D3")
    static let greenTea = Color(hex: "#7DAA6E")
    
    // 輔助色
    static let bubbleBlack = Color(hex: "#2C2C2C")
    static let fruitOrange = Color(hex: "#FF8C42")
    static let coffeeBrown = Color(hex: "#6F4E37")
    static let milkWhite = Color(hex: "#FDFCFB")
    static let specialPurple = Color(hex: "#9B59B6")
    
    // 熱量警示色
    static let caloriesLow = Color(hex: "#4CAF50")    // 綠色 < 200
    static let caloriesMedium = Color(hex: "#FF9800") // 橙色 200-500
    static let caloriesHigh = Color(hex: "#F44336")   // 紅色 > 500
    
    // 背景色
    static let backgroundPrimary = Color(hex: "#FFFBF5")
    static let backgroundSecondary = Color(hex: "#FFF8F0")
    static let backgroundCard = Color.white
    
    // MARK: - Hex Initializer
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - 熱量顏色
extension Color {
    /// 根據熱量值取得對應顏色
    static func forCalories(_ calories: Int) -> Color {
        switch calories {
        case 0..<200:
            return .caloriesLow
        case 200...500:
            return .caloriesMedium
        default:
            return .caloriesHigh
        }
    }
}

// MARK: - 漸層
extension LinearGradient {
    static let teaGradient = LinearGradient(
        colors: [Color.teaBrown.opacity(0.8), Color.milkCream],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let cardGradient = LinearGradient(
        colors: [Color.white, Color.milkCream.opacity(0.3)],
        startPoint: .top,
        endPoint: .bottom
    )
}
