import Foundation

/// 篩選條件
struct FilterCriteria: Equatable {
    var selectedBrands: Set<String> = []
    var selectedCategories: Set<DrinkCategory> = []
    var selectedSugarLevel: SugarLevel? = nil  // 改為單選，用於計算熱量
    var calorieRange: CalorieRange?
    var hasCaffeine: Bool?
    
    // Pro 功能
    var smartPriority: Bool = false  // 優先推薦 (≥4星)
    var antiThunder: Bool = false    // 避雷模式 (排除≤2星)
    
    /// 是否為空篩選條件
    var isEmpty: Bool {
        selectedBrands.isEmpty &&
        selectedCategories.isEmpty &&
        selectedSugarLevel == nil &&
        calorieRange == nil &&
        hasCaffeine == nil
    }
    
    /// 篩選條件數量 (用於 UI 顯示 badge)
    var activeFilterCount: Int {
        var count = 0
        if !selectedBrands.isEmpty { count += 1 }
        if !selectedCategories.isEmpty { count += 1 }
        if selectedSugarLevel != nil { count += 1 }
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
        
        // 甜度篩選：檢查飲品是否支援選擇的甜度
        if let sugar = selectedSugarLevel {
            if !drink.availableSugarLevels.contains(sugar) {
                return false
            }
        }
        
        // 熱量篩選：根據選擇的甜度計算熱量
        if let range = calorieRange {
            let calories = caloriesForDrink(drink)
            if !range.range.contains(calories) {
                return false
            }
        }
        
        // 咖啡因篩選
        if let caffeineCondition = hasCaffeine {
            // 如果飲料的 hasCaffeine 為 nil (未知)，則不符合任何明確的篩選條件 (無論是查有或查無)
            guard let drinkHasCaffeine = drink.hasCaffeine else {
                return false
            }
            
            if drinkHasCaffeine != caffeineCondition {
                return false
            }
        }
        
        return true
    }
    
    /// 根據選擇的甜度計算熱量（用於篩選和顯示）
    func caloriesForDrink(_ drink: Drink) -> Int {
        if let sugar = selectedSugarLevel {
            return drink.calories(for: sugar)
        }
        return drink.baseCalories
    }
    
    /// 重置所有篩選條件
    mutating func reset() {
        selectedBrands = []
        selectedCategories = []
        selectedSugarLevel = nil
        calorieRange = nil
        hasCaffeine = nil
        smartPriority = false
        antiThunder = false
    }
}

