import Foundation

/// 口感風味評鑑命名空間
/// 包含 6 個主觀感受維度，每個維度 4~5 個級距
enum TasteProfile {
    
    // MARK: - 1. 配料口感
    
    enum ToppingTexture: String, CaseIterable, Identifiable {
        case veryChewy   = "texture_very_chewy"
        case chewy       = "texture_chewy"
        case normal      = "texture_normal"
        case softish     = "texture_softish"
        case mushy       = "texture_mushy"
        
        var id: String { rawValue }
        
        var displayName: String {
            switch self {
            case .veryChewy: return "非常有嚼勁"
            case .chewy:     return "有嚼勁"
            case .normal:    return "普通"
            case .softish:   return "偏軟爛"
            case .mushy:     return "軟爛"
            }
        }
        
        var icon: String { "mouth" }
    }
    
    // MARK: - 2. 茶味濃度
    
    enum TeaStrength: String, CaseIterable, Identifiable {
        case rich      = "tea_rich"
        case fairlyRich = "tea_fairly_rich"
        case normal    = "tea_normal"
        case light     = "tea_light"
        case veryLight = "tea_very_light"
        
        var id: String { rawValue }
        
        var displayName: String {
            switch self {
            case .rich:       return "濃郁"
            case .fairlyRich: return "偏濃郁"
            case .normal:     return "一般"
            case .light:      return "偏淡"
            case .veryLight:  return "很淡"
            }
        }
        
        var icon: String { "leaf" }
    }
    
    // MARK: - 3. 奶味濃度
    
    enum MilkStrength: String, CaseIterable, Identifiable {
        case rich      = "milk_rich"
        case fairlyRich = "milk_fairly_rich"
        case normal    = "milk_normal"
        case light     = "milk_light"
        case veryLight = "milk_very_light"
        
        var id: String { rawValue }
        
        var displayName: String {
            switch self {
            case .rich:       return "濃郁"
            case .fairlyRich: return "偏濃郁"
            case .normal:     return "一般"
            case .light:      return "偏淡"
            case .veryLight:  return "很淡"
            }
        }
        
        var icon: String { "drop.fill" }
    }
    
    // MARK: - 4. 甜度感受
    
    enum SweetnessFeeling: String, CaseIterable, Identifiable {
        case verySweet    = "sweet_very_sweet"
        case sweet        = "sweet_sweet"
        case normal       = "sweet_normal"
        case lessSweet    = "sweet_less"
        case notSweet     = "sweet_not"
        
        var id: String { rawValue }
        
        var displayName: String {
            switch self {
            case .verySweet:  return "非常甜"
            case .sweet:      return "偏甜"
            case .normal:     return "正常"
            case .lessSweet:  return "偏不甜"
            case .notSweet:   return "很不甜"
            }
        }
        
        var icon: String { "cube.fill" }
    }
    
    // MARK: - 5. 冰塊感受
    
    enum IceFeeling: String, CaseIterable, Identifiable {
        case tooMuch  = "ice_too_much"
        case justRight = "ice_just_right"
        case less     = "ice_less"
        case almostNone = "ice_almost_none"
        
        var id: String { rawValue }
        
        var displayName: String {
            switch self {
            case .tooMuch:    return "太多冰"
            case .justRight:  return "冰塊剛好"
            case .less:       return "偏少"
            case .almostNone: return "幾乎沒冰"
            }
        }
        
        var icon: String { "snowflake" }
    }
    
    // MARK: - 6. 順口度
    
    enum Smoothness: String, CaseIterable, Identifiable {
        case verySmooth = "smooth_very"
        case smooth     = "smooth_smooth"
        case normal     = "smooth_normal"
        case slight     = "smooth_slight_astringent"
        case astringent = "smooth_astringent"
        
        var id: String { rawValue }
        
        var displayName: String {
            switch self {
            case .verySmooth: return "非常順口"
            case .smooth:     return "順口"
            case .normal:     return "普通"
            case .slight:     return "微澀"
            case .astringent: return "澀感明顯"
            }
        }
        
        var icon: String { "waveform.path" }
    }
    
    // MARK: - Dimension Definition
    
    /// 維度定義（用於 UI 渲染）
    struct Dimension {
        let title: String
        let icon: String
        let options: [(value: String, label: String)]
    }
    
    /// 所有維度（按顯示順序）
    static let allDimensions: [Dimension] = [
        Dimension(
            title: "配料口感",
            icon: "mouth",
            options: ToppingTexture.allCases.map { ($0.rawValue, $0.displayName) }
        ),
        Dimension(
            title: "茶味",
            icon: "leaf",
            options: TeaStrength.allCases.map { ($0.rawValue, $0.displayName) }
        ),
        Dimension(
            title: "奶味",
            icon: "drop.fill",
            options: MilkStrength.allCases.map { ($0.rawValue, $0.displayName) }
        ),
        Dimension(
            title: "甜度感受",
            icon: "cube.fill",
            options: SweetnessFeeling.allCases.map { ($0.rawValue, $0.displayName) }
        ),
        Dimension(
            title: "冰塊感受",
            icon: "snowflake",
            options: IceFeeling.allCases.map { ($0.rawValue, $0.displayName) }
        ),
        Dimension(
            title: "順口度",
            icon: "waveform.path",
            options: Smoothness.allCases.map { ($0.rawValue, $0.displayName) }
        ),
    ]
}
