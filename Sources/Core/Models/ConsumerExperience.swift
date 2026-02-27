import Foundation

/// 消費體驗命名空間
/// 包含 5 個消費感受維度
enum ConsumerExperience {
    
    // MARK: - 1. CP 值
    
    enum CostPerformance: String, CaseIterable, Identifiable {
        case excellent = "cp_excellent"
        case worthIt   = "cp_worth_it"
        case normal    = "cp_normal"
        case pricey    = "cp_pricey"
        case tooExpensive = "cp_too_expensive"
        
        var id: String { rawValue }
        
        var displayName: String {
            switch self {
            case .excellent:    return "超值"
            case .worthIt:      return "物有所值"
            case .normal:       return "普通"
            case .pricey:       return "有點貴"
            case .tooExpensive: return "太貴了"
            }
        }
    }
    
    // MARK: - 2. 飲用情境
    
    enum DrinkingOccasion: String, CaseIterable, Identifiable {
        case workBoost   = "occasion_work"
        case afterMeal   = "occasion_after_meal"
        case afternoonTea = "occasion_afternoon"
        case postWorkout = "occasion_workout"
        case social      = "occasion_social"
        case selfTreat   = "occasion_self_treat"
        
        var id: String { rawValue }
        
        var displayName: String {
            switch self {
            case .workBoost:    return "上班提神"
            case .afterMeal:    return "飯後解膩"
            case .afternoonTea: return "下午茶"
            case .postWorkout:  return "運動後"
            case .social:       return "社交聚會"
            case .selfTreat:    return "療癒犒賞"
            }
        }
    }
    
    // MARK: - 3. 再回購？
    
    enum Repurchase: String, CaseIterable, Identifiable {
        case definitely = "repurchase_yes"
        case maybe      = "repurchase_maybe"
        case unsure     = "repurchase_unsure"
        case unlikely   = "repurchase_unlikely"
        case never      = "repurchase_never"
        
        var id: String { rawValue }
        
        var displayName: String {
            switch self {
            case .definitely: return "一定會"
            case .maybe:      return "可能會"
            case .unsure:     return "不確定"
            case .unlikely:   return "應該不會"
            case .never:      return "絕對不會"
            }
        }
    }
    
    // MARK: - 4. 份量
    
    enum PortionSize: String, CaseIterable, Identifiable {
        case overflowing = "portion_overflowing"
        case justRight   = "portion_just_right"
        case aLittleLess = "portion_little_less"
        case tooLittle   = "portion_too_little"
        
        var id: String { rawValue }
        
        var displayName: String {
            switch self {
            case .overflowing: return "超滿"
            case .justRight:   return "剛好"
            case .aLittleLess: return "有點少"
            case .tooLittle:   return "很少"
            }
        }
    }
    
    // MARK: - 5. 等待時長
    
    enum WaitTime: String, CaseIterable, Identifiable {
        case superFast = "wait_super_fast"
        case normal    = "wait_normal"
        case aWhile    = "wait_a_while"
        case tooLong   = "wait_too_long"
        
        var id: String { rawValue }
        
        var displayName: String {
            switch self {
            case .superFast: return "超快（<3分鐘）"
            case .normal:    return "正常"
            case .aWhile:    return "有點久"
            case .tooLong:   return "超久（>15分鐘）"
            }
        }
    }
    
    // MARK: - Dimension Definition
    
    struct Dimension {
        let title: String
        let icon: String
        let options: [(value: String, label: String)]
    }
    
    /// 所有維度（按顯示順序）
    static let allDimensions: [Dimension] = [
        Dimension(
            title: "CP 值",
            icon: "dollarsign.circle",
            options: CostPerformance.allCases.map { ($0.rawValue, $0.displayName) }
        ),
        Dimension(
            title: "飲用情境",
            icon: "location.fill",
            options: DrinkingOccasion.allCases.map { ($0.rawValue, $0.displayName) }
        ),
        Dimension(
            title: "再回購？",
            icon: "arrow.counterclockwise",
            options: Repurchase.allCases.map { ($0.rawValue, $0.displayName) }
        ),
        Dimension(
            title: "份量",
            icon: "cup.and.saucer.fill",
            options: PortionSize.allCases.map { ($0.rawValue, $0.displayName) }
        ),
        Dimension(
            title: "等待時長",
            icon: "clock",
            options: WaitTime.allCases.map { ($0.rawValue, $0.displayName) }
        ),
    ]
}
