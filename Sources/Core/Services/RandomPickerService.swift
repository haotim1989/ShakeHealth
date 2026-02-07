import Foundation

/// 隨機推薦服務協議
protocol RandomPickerServiceProtocol {
    func pickRandom(from drinks: [Drink], criteria: FilterCriteria) -> Drink?
    func getFilteredDrinks(criteria: FilterCriteria, userLogs: [DrinkLog]) async throws -> [Drink]
}

/// 智慧推薦結果
struct SmartPickResult {
    let drinks: [Drink]
    let hasInsufficientData: Bool  // 資料不足，已 fallback 到普通隨機
}

/// 隨機推薦服務實作
final class RandomPickerService: RandomPickerServiceProtocol {
    static let shared = RandomPickerService()
    
    private let drinkService: DrinkServiceProtocol
    
    /// 智慧推薦的最低資料門檻 (至少要有 3 筆有評分的紀錄)
    private let minLogsForSmartRecommendation = 3
    
    init(drinkService: DrinkServiceProtocol = DrinkService.shared) {
        self.drinkService = drinkService
    }
    
    /// 從飲料陣列中隨機選取一筆符合條件的
    func pickRandom(from drinks: [Drink], criteria: FilterCriteria) -> Drink? {
        let filtered = drinks.filter { criteria.matches($0) }
        guard !filtered.isEmpty else { return nil }
        return filtered.randomElement()
    }
    
    /// 取得所有符合篩選條件的飲料 (含智慧推薦/避雷模式)
    func getFilteredDrinks(criteria: FilterCriteria, userLogs: [DrinkLog] = []) async throws -> [Drink] {
        let allDrinks = try await drinkService.fetchAllDrinks()
        
        // 先套用基本篩選條件
        var filtered = criteria.isEmpty ? allDrinks : allDrinks.filter { criteria.matches($0) }
        
        // 避雷模式：排除 1-2 星評價的飲料
        if criteria.antiThunder {
            filtered = applyAvoidMode(to: filtered, logs: userLogs)
        }
        
        // 智慧推薦：加權抽選 (80% 高評/常喝，20% 新飲料)
        if criteria.smartPriority {
            filtered = applySmartRecommendation(to: filtered, logs: userLogs)
        }
        
        return filtered
    }
    
    // MARK: - 避雷模式
    
    /// 排除用戶評價 1-2 星的飲料
    private func applyAvoidMode(to drinks: [Drink], logs: [DrinkLog]) -> [Drink] {
        // 取得所有評價 <= 2 星的飲料 ID
        let lowRatedDrinkIds = Set(
            logs.filter { $0.rating <= 2 }
                .map { $0.drinkId }
        )
        
        // 排除這些飲料
        return drinks.filter { !lowRatedDrinkIds.contains($0.id) }
    }
    
    // MARK: - 智慧推薦
    
    /// 智慧推薦邏輯：
    /// - 80% 機率從「偏好池」抽取 (4-5星評價 + 常喝的品牌/品類)
    /// - 20% 機率從「探索池」抽取 (從未喝過的飲料)
    private func applySmartRecommendation(to drinks: [Drink], logs: [DrinkLog]) -> [Drink] {
        // 資料不足時直接返回全部
        let ratedLogs = logs.filter { $0.rating > 0 }
        guard ratedLogs.count >= minLogsForSmartRecommendation else {
            return drinks
        }
        
        // 取得高評價飲料 ID (4-5星)
        let highRatedDrinkIds = Set(
            ratedLogs.filter { $0.rating >= 4 }
                     .map { $0.drinkId }
        )
        
        // 取得喝過的飲料 ID
        let triedDrinkIds = Set(logs.map { $0.drinkId })
        
        // 統計最常喝的品牌 (取前 3 名)
        let brandCounts = Dictionary(grouping: logs, by: { $0.brandId })
            .mapValues { $0.count }
            .sorted { $0.value > $1.value }
            .prefix(3)
            .map { $0.key }
        let favoriteBrands = Set(brandCounts)
        
        // 分類飲料
        var priorityPool: [Drink] = []  // 偏好池
        var explorationPool: [Drink] = []  // 探索池
        
        for drink in drinks {
            if highRatedDrinkIds.contains(drink.id) || favoriteBrands.contains(drink.brandId) {
                // 高評價或常喝品牌 → 偏好池
                priorityPool.append(drink)
            } else if !triedDrinkIds.contains(drink.id) {
                // 沒喝過 → 探索池
                explorationPool.append(drink)
            }
        }
        
        // 決定從哪個池抽取 (80% 偏好池，20% 探索池)
        let random = Double.random(in: 0...1)
        
        if random < 0.8 && !priorityPool.isEmpty {
            return priorityPool
        } else if !explorationPool.isEmpty {
            return explorationPool
        } else if !priorityPool.isEmpty {
            return priorityPool
        } else {
            // 兩個池都空，回傳原始列表
            return drinks
        }
    }
    
    /// 檢查是否有足夠資料進行智慧推薦
    func hasInsufficientData(logs: [DrinkLog]) -> Bool {
        let ratedLogs = logs.filter { $0.rating > 0 }
        return ratedLogs.count < minLogsForSmartRecommendation
    }
}
