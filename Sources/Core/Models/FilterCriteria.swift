import Foundation

/// 篩選條件
struct FilterCriteria: Equatable {
    var selectedBrands: Set<String> = []
    var selectedCategories: Set<DrinkCategory> = []
    var selectedSugarLevels: Set<SugarLevel> = []
    var calorieRange: CalorieRange?
    var hasCaffeine: Bool?
    
    /// 是否為空篩選條件
    var isEmpty: Bool {
        selectedBrands.isEmpty &&
        selectedCategories.isEmpty &&
        selectedSugarLevels.isEmpty &&
        calorieRange == nil &&
        hasCaffeine == nil
    }
    
    /// 篩選條件數量 (用於 UI 顯示 badge)
    var activeFilterCount: Int {
        var count = 0
        if !selectedBrands.isEmpty { count += 1 }
        if !selectedCategories.isEmpty { count += 1 }
        if !selectedSugarLevels.isEmpty { count += 1 }
        if calorieRange != nil { count += 1 }
        if hasCaffeine != nil { count += 1 }
        return count
    }
    
    /// 檢查飲品是否符合篩選條件
    func matches(_ drink: Drink) -> Bool {
        // 品牌篩選
        if !selectedBrands.isEmpty && !selectedBrands.contains(drink.brandId) {
            return false
        }
        
        // 分類篩選
        if !selectedCategories.isEmpty && !selectedCategories.contains(drink.category) {
            return false
        }
        
        // 甜度篩選 (檢查飲品是否支援任一選擇的甜度)
        if !selectedSugarLevels.isEmpty {
            let available = Set(drink.availableSugarLevels)
            if selectedSugarLevels.isDisjoint(with: available) {
                return false
            }
        }
        
        // 熱量篩選
        if let range = calorieRange, !range.range.contains(drink.baseCalories) {
            return false
        }
        
        // 咖啡因篩選
        if let caffeine = hasCaffeine, drink.hasCaffeine != caffeine {
            return false
        }
        
        return true
    }
    
    /// 重置所有篩選條件
    mutating func reset() {
        selectedBrands = []
        selectedCategories = []
        selectedSugarLevels = []
        calorieRange = nil
        hasCaffeine = nil
    }
}
