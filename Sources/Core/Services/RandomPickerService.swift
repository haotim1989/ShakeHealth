import Foundation

/// 隨機推薦服務協議
protocol RandomPickerServiceProtocol {
    func pickRandom(from drinks: [Drink], criteria: FilterCriteria) -> Drink?
    func getFilteredDrinks(criteria: FilterCriteria) async throws -> [Drink]
}

/// 隨機推薦服務實作
final class RandomPickerService: RandomPickerServiceProtocol {
    static let shared = RandomPickerService()
    
    private let drinkService: DrinkServiceProtocol
    
    init(drinkService: DrinkServiceProtocol = DrinkService.shared) {
        self.drinkService = drinkService
    }
    
    /// 從飲料陣列中隨機選取一筆符合條件的
    func pickRandom(from drinks: [Drink], criteria: FilterCriteria) -> Drink? {
        let filtered = drinks.filter { criteria.matches($0) }
        guard !filtered.isEmpty else { return nil }
        return filtered.randomElement()
    }
    
    /// 取得所有符合篩選條件的飲料
    func getFilteredDrinks(criteria: FilterCriteria) async throws -> [Drink] {
        let allDrinks = try await drinkService.fetchAllDrinks()
        
        // 如果沒有任何篩選條件，回傳全部
        if criteria.isEmpty {
            return allDrinks
        }
        
        return allDrinks.filter { criteria.matches($0) }
    }
}
