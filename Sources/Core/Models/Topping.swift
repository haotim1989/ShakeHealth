import Foundation

/// 飲料配料（依據營養師熱量表分為紅黃綠三燈區）
/// 熱量為飲料店 2 大湯匙（約 60g）之估算值，飲品大杯 700ml 正常冰估算
enum Topping: String, CaseIterable, Identifiable, Hashable, Codable {
    // 🔴 紅燈區 (144~203 kcal)
    case creamCap       = "cream_cap"       // 奶蓋
    case grassJelly2    = "grass_cake"       // 草仔粿
    case sago           = "sago"            // 西米露
    case riceCake       = "rice_cake"       // 粉粿
    case iceCream       = "ice_cream"       // 冰淇淋
    case bobaPearl      = "boba_pearl"      // 波霸珍珠
    case sweetPotato    = "sweet_potato"    // 蜜地瓜/芋頭
    case yakult         = "yakult"          // 多多
    
    // 🟡 黃燈區 (110~131 kcal)
    case noodle         = "noodle"          // 粉條
    case taroball       = "taro_ball"       // 芋圓
    case oreo           = "oreo"            // Oreo脆片
    case pudding        = "pudding"         // 布丁
    
    // 🟢 綠燈區 (31~76 kcal)
    case coconutJelly   = "coconut_jelly"   // 椰果
    case konjac         = "konjac"          // 蒟蒻
    case grassJelly     = "grass_jelly"     // 仙草
    case aiyu           = "aiyu"            // 愛玉
    case kantens        = "kanten"          // 寒天
    case aloeVera       = "aloe_vera"       // 蘆薈
    
    var id: String { rawValue }
    
    // MARK: - Display
    
    var displayName: String {
        switch self {
        case .creamCap:     return "奶蓋"
        case .grassJelly2:  return "草仔粿"
        case .sago:         return "西米露"
        case .riceCake:     return "粉粿"
        case .iceCream:     return "冰淇淋"
        case .bobaPearl:    return "波霸珍珠"
        case .sweetPotato:  return "蜜地瓜/芋頭"
        case .yakult:       return "多多"
        case .noodle:       return "粉條"
        case .taroball:     return "芋圓"
        case .oreo:         return "Oreo脆片"
        case .pudding:      return "布丁"
        case .coconutJelly: return "椰果"
        case .konjac:       return "蒟蒻"
        case .grassJelly:   return "仙草"
        case .aiyu:         return "愛玉"
        case .kantens:      return "寒天"
        case .aloeVera:     return "蘆薈"
        }
    }
    
    /// 配料熱量 (kcal)
    var calories: Int {
        switch self {
        case .creamCap:     return 203
        case .grassJelly2:  return 168
        case .sago:         return 165
        case .riceCake:     return 165
        case .iceCream:     return 160
        case .bobaPearl:    return 156
        case .sweetPotato:  return 150
        case .yakult:       return 144
        case .noodle:       return 131
        case .taroball:     return 128
        case .oreo:         return 116
        case .pudding:      return 110
        case .coconutJelly: return 76
        case .konjac:       return 71
        case .grassJelly:   return 57
        case .aiyu:         return 45
        case .kantens:      return 42
        case .aloeVera:     return 31
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
            case .red:    return "144~203 kcal"
            case .yellow: return "110~131 kcal"
            case .green:  return "31~76 kcal"
            }
        }
    }
    
    var tier: Tier {
        switch self {
        case .creamCap, .grassJelly2, .sago, .riceCake, .iceCream, .bobaPearl, .sweetPotato, .yakult:
            return .red
        case .noodle, .taroball, .oreo, .pudding:
            return .yellow
        case .coconutJelly, .konjac, .grassJelly, .aiyu, .kantens, .aloeVera:
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
