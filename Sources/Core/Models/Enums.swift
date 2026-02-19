import Foundation
import SwiftUI

/// 甜度等級
enum SugarLevel: String, Codable, CaseIterable, Identifiable {
    case sugar0 = "無糖"
    case sugar30 = "微糖"
    case sugar50 = "半糖"
    case sugar70 = "少糖"
    case sugar100 = "正常"
    
    var id: String { rawValue }
    
    /// 熱量係數 (相對於正常糖)
    var multiplier: Double {
        switch self {
        case .sugar0: return 0.6
        case .sugar30: return 0.75
        case .sugar50: return 0.85
        case .sugar70: return 0.92
        case .sugar100: return 1.0
        }
    }
    
    /// 顯示用短名稱
    var shortName: String {
        switch self {
        case .sugar0: return "無糖"
        case .sugar30: return "微糖"
        case .sugar50: return "半糖"
        case .sugar70: return "少糖"
        case .sugar100: return "全糖"
        }
    }
    
    /// 糖分比例 (0.0 - 1.0)
    /// 微糖=40%, 半糖=60%, 少糖=80%, 全糖=100%
    var sugarPercentage: Double {
        switch self {
        case .sugar0: return 0.0
        case .sugar30: return 0.4   // 微糖
        case .sugar50: return 0.6   // 半糖
        case .sugar70: return 0.8   // 少糖
        case .sugar100: return 1.0  // 全糖
        }
    }
}

/// 冰塊等級
enum IceLevel: String, Codable, CaseIterable, Identifiable {
    case noIce = "去冰"
    case lessIce = "少冰"
    case lightIce = "微冰"
    case normalIce = "正常冰"
    case hot = "熱飲"
    
    var id: String { rawValue }
}

/// 飲品分類
enum DrinkCategory: String, Codable, CaseIterable, Identifiable {
    case milkTea = "奶茶類"
    case pureTea = "原茶類"
    case fruitTea = "果茶類"
    case coffee = "咖啡類"
    case fresh = "鮮奶系列"
    case special = "特調類"
    
    var id: String { rawValue }
    
    /// 分類圖示
    var iconName: String {
        switch self {
        case .milkTea: return "cup.and.saucer.fill"
        case .pureTea: return "leaf.fill"
        case .fruitTea: return "drop.fill"
        case .coffee: return "mug.fill"
        case .fresh: return "drop.circle.fill"
        case .special: return "sparkles"
        }
    }
    
    /// 分類顏色
    var color: String {
        switch self {
        case .milkTea: return "teaBrown"
        case .pureTea: return "greenTea"
        case .fruitTea: return "fruitOrange"
        case .coffee: return "coffeeBrown"
        case .fresh: return "coffeeBrown"
        case .special: return "specialBlue"
        }
    }
    
    /// 分類主題色（SwiftUI Color）
    var themeColor: Color {
        switch self {
        case .milkTea: return .teaBrown
        case .pureTea: return .greenTea
        case .fruitTea: return .fruitOrange
        case .coffee: return .coffeeBrown
        case .fresh: return .coffeeBrown
        case .special: return .specialBlue
        }
    }
}

/// 熱量區間
enum CalorieRange: String, CaseIterable, Identifiable {
    case low = "低熱量"     // < 200 kcal
    case medium = "中熱量"  // 200-500 kcal
    case high = "高熱量"    // > 500 kcal
    
    var id: String { rawValue }
    
    /// 熱量範圍
    var range: ClosedRange<Int> {
        switch self {
        case .low: return 0...199
        case .medium: return 200...500
        case .high: return 501...9999
        }
    }
    
    /// 顯示描述
    var description: String {
        switch self {
        case .low: return "< 200 kcal"
        case .medium: return "200-500 kcal"
        case .high: return "> 500 kcal"
        }
    }
    
    /// 指示顏色
    var colorName: String {
        switch self {
        case .low: return "caloriesLow"
        case .medium: return "caloriesMedium"
        case .high: return "caloriesHigh"
        }
    }
}
