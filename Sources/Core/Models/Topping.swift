import Foundation

/// 飲料配料（依據營養師熱量表分為紅黃綠三燈區）
/// 熱量為飲料店 2 大湯匙（約 60g）之估算值，飲品大杯 700ml 正常冰估算
enum Topping: String, CaseIterable, Identifiable, Hashable, Codable {
    // 🔴 紅燈區 (151 kcal 以上)
    case creamCap       = "cream_cap"       // 奶蓋
    case grassJelly2    = "grass_cake"      // 草仔粿
    case bobaPearl      = "boba_pearl"      // 波霸珍珠
    case riceCake       = "rice_cake"       // 粉粿
    case sago           = "sago"            // 西米露
    case chewySquare    = "chewy_square"    // 粉角
    case iceCream       = "ice_cream"       // 冰淇淋
    
    // 🟡 黃燈區 (100~150 kcal)
    case sweetPotato    = "sweet_potato"    // 蜜地瓜
    case taro           = "taro"            // 芋頭
    case yakult         = "yakult"          // 多多
    case noodle         = "noodle"          // 粉條
    case oats           = "oats"            // 燕麥 / 小麥
    case milkPudding    = "milk_pudding"    // 奶凍
    case taroball       = "taro_ball"       // 芋圓
    case pudding        = "pudding"         // 布丁
    case oreo           = "oreo"            // Oreo脆片
    
    // 🟢 綠燈區 (100 kcal 以下)
    case coconutJelly   = "coconut_jelly"   // 椰果
    case almondJelly    = "almond_jelly"    // 杏仁凍
    case tofuPudding    = "tofu_pudding"    // 豆花
    case konjac         = "konjac"          // 蒟蒻
    case kantens        = "kanten"          // 寒天
    case teaJelly       = "tea_jelly"       // 茶凍 / 桂花凍
    case basilSeeds     = "basil_seeds"     // 小紫蘇 / 奇亞籽
    case grassJelly     = "grass_jelly"     // 仙草
    case aiyu           = "aiyu"            // 愛玉
    case aloeVera       = "aloe_vera"       // 蘆薈
    
    var id: String { rawValue }
    
    // MARK: - Display
    
    var displayName: String {
        switch self {
        case .creamCap:     return "奶蓋"
        case .grassJelly2:  return "草仔粿"
        case .bobaPearl:    return "珍珠"
        case .riceCake:     return "粉粿"
        case .sago:         return "西米露"
        case .chewySquare:  return "粉角"
        case .iceCream:     return "冰淇淋"
        
        case .sweetPotato:  return "蜜地瓜"
        case .taro:         return "芋頭"
        case .yakult:       return "多多"
        case .noodle:       return "粉條"
        case .oats:         return "燕麥/小麥"
        case .milkPudding:  return "奶凍"
        case .taroball:     return "芋圓"
        case .pudding:      return "布丁"
        case .oreo:         return "Oreo脆片"
        
        case .coconutJelly: return "椰果"
        case .almondJelly:  return "杏仁凍"
        case .tofuPudding:  return "豆花"
        case .konjac:       return "蒟蒻"
        case .kantens:      return "寒天"
        case .teaJelly:     return "茶/桂花凍"
        case .basilSeeds:   return "小紫蘇/奇亞籽"
        case .grassJelly:   return "仙草"
        case .aiyu:         return "愛玉"
        case .aloeVera:     return "蘆薈"
        }
    }
    
    /// 配料熱量 (kcal)
    var calories: Int {
        switch self {
        case .creamCap:     return 230
        case .grassJelly2:  return 210
        case .bobaPearl:    return 190
        case .riceCake:     return 185
        case .sago:         return 175
        case .chewySquare:  return 165
        case .iceCream:     return 160
        
        case .sweetPotato:  return 150
        case .taro:         return 150
        case .yakult:       return 150
        case .noodle:       return 145
        case .oats:         return 145
        case .milkPudding:  return 140
        case .taroball:     return 135
        case .pudding:      return 115
        case .oreo:         return 110
        
        case .coconutJelly: return 85
        case .almondJelly:  return 85
        case .tofuPudding:  return 75
        case .konjac:       return 50
        case .kantens:      return 50
        case .teaJelly:     return 45
        case .basilSeeds:   return 40
        case .grassJelly:   return 35
        case .aiyu:         return 35
        case .aloeVera:     return 30
        }
    }
    
    // MARK: - Tier
    
    enum Tier: String, CaseIterable {
        case red, yellow, green
        
        var displayName: String {
            switch self {
            case .red:    return "紅燈區"
            case .yellow: return "黃燈區"
            case .green:  return "綠燈區"
            }
        }
        
        var calorieRange: String {
            switch self {
            case .red:    return "151 kcal 以上"
            case .yellow: return "100~150 kcal"
            case .green:  return "100 kcal 以下"
            }
        }
    }
    
    var tier: Tier {
        switch self {
        case .creamCap, .grassJelly2, .bobaPearl, .riceCake, .sago, .chewySquare, .iceCream:
            return .red
        case .sweetPotato, .taro, .yakult, .noodle, .oats, .milkPudding, .taroball, .pudding, .oreo:
            return .yellow
        case .coconutJelly, .almondJelly, .tofuPudding, .konjac, .kantens, .teaJelly, .basilSeeds, .grassJelly, .aiyu, .aloeVera:
            return .green
        }
    }
    
    /// 按燈區分組排列
    static var grouped: [(tier: Tier, toppings: [Topping])] {
        Tier.allCases.map { tier in
            (tier: tier, toppings: allCases.filter { $0.tier == tier })
        }
    }
    
    // MARK: - Serialization
    
    /// 將配料 Set 序列化為逗號分隔字串
    static func serialize(_ toppings: Set<Topping>) -> String {
        toppings.map(\.rawValue).sorted().joined(separator: ",")
    }
    
    /// 從逗號分隔字串反序列化為 Set
    static func deserialize(_ string: String) -> Set<Topping> {
        guard !string.isEmpty else { return [] }
        return Set(string.split(separator: ",").compactMap { Topping(rawValue: String($0)) })
    }
    
    /// 計算一組配料的總熱量
    static func totalCalories(_ toppings: Set<Topping>) -> Int {
        toppings.reduce(0) { $0 + $1.calories }
    }
}
