import Foundation

/// 隨機推薦服務協議
protocol RandomPickerServiceProtocol {
    func pickRandom(from drinks: [Drink], criteria: FilterCriteria) -> Drink?
    func getFilteredDrinks(criteria: FilterCriteria, userLogs: [DrinkLog]) async throws -> [Drink]
}

/// 隨機推薦服務實作
final class RandomPickerService: RandomPickerServiceProtocol {
    static let shared = RandomPickerService()
    
    private let drinkService: DrinkServiceProtocol
    
    /// 智慧推薦的最低資料門檻 (至少要有 10 筆不重複飲料紀錄)
    private let minLogsForSmartRecommendation = 10
    
    /// 偏好池最少需要的飲料數量，否則 fallback 到探索池
    private let minPriorityPoolSize = 3
    
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
        
        // 避雷模式：只排除評價 1-2 星的特定飲料 (不排除品牌)
        if criteria.antiThunder {
            filtered = applyAvoidMode(to: filtered, logs: userLogs)
        }
        
        // 智慧推薦：動態機率決定從偏好池或探索池抽取
        if criteria.smartPriority {
            filtered = applySmartRecommendation(to: filtered, logs: userLogs)
        }
        
        return filtered
    }
    
    // MARK: - 避雷模式
    
    /// 只排除用戶給 1-2 星的特定飲料 (不影響同品牌其他飲料)
    private func applyAvoidMode(to drinks: [Drink], logs: [DrinkLog]) -> [Drink] {
        // 取得所有評價 1-2 星的特定飲料 ID
        let lowRatedDrinkIds = Set(
            logs.filter { $0.rating >= 1 && $0.rating <= 2 }
                .map { $0.drinkId }
        )
        
        // 只排除這些特定飲料，不影響同品牌其他飲料
        return drinks.filter { !lowRatedDrinkIds.contains($0.id) }
    }
    
    // MARK: - 智慧推薦
    
    /// 計算不重複飲料數量
    private func uniqueDrinkCount(from logs: [DrinkLog]) -> Int {
        return Set(logs.map { $0.drinkId }).count
    }
    
    /// 根據資料量取得偏好池機率
    /// - < 10 筆：0% (完全隨機)
    /// - 10-19 筆：20%
    /// - 20-29 筆：50%
    /// - 30-49 筆：70%
    /// - >= 50 筆：90%
    private func getPriorityPoolProbability(uniqueCount: Int) -> Double {
        switch uniqueCount {
        case 0..<10:
            return 0.0
        case 10..<20:
            return 0.2
        case 20..<30:
            return 0.5
        case 30..<50:
            return 0.7
        default:
            return 0.9
        }
    }
    
    /// 智慧推薦主邏輯
    private func applySmartRecommendation(to drinks: [Drink], logs: [DrinkLog]) -> [Drink] {
        let uniqueCount = uniqueDrinkCount(from: logs)
        
        // 資料不足時直接返回全部 (探索模式)
        guard uniqueCount >= minLogsForSmartRecommendation else {
            return drinks
        }
        
        // 取得偏好池 (只包含 4-5 星評價的飲料)
        let highRatedDrinkIds = Set(
            logs.filter { $0.rating >= 4 }
                .map { $0.drinkId }
        )
        let priorityPool = drinks.filter { highRatedDrinkIds.contains($0.id) }
        
        // 取得探索池 (不在偏好池中的其他飲料)
        let explorationPool = drinks.filter { !highRatedDrinkIds.contains($0.id) }
        
        // 如果偏好池太小，強制使用探索池
        guard priorityPool.count >= minPriorityPoolSize else {
            return explorationPool.isEmpty ? drinks : explorationPool
        }
        
        // 動態機率決定抽哪個池
        let probability = getPriorityPoolProbability(uniqueCount: uniqueCount)
        let random = Double.random(in: 0...1)
        
        if random < probability {
            // 命中偏好池：加權抽取 (5星=3倍權重，4星=1倍權重)
            return applyWeightedPriorityPool(priorityPool: priorityPool, logs: logs)
        } else {
            // 命中探索池
            return explorationPool.isEmpty ? drinks : explorationPool
        }
    }
    
    /// 對偏好池進行加權處理 (5星=3倍權重，4星=1倍權重)
    private func applyWeightedPriorityPool(priorityPool: [Drink], logs: [DrinkLog]) -> [Drink] {
        // 取得 5 星飲料 ID
        let fiveStarIds = Set(
            logs.filter { $0.rating == 5 }
                .map { $0.drinkId }
        )
        
        // 建立加權陣列
        var weightedPool: [Drink] = []
        for drink in priorityPool {
            if fiveStarIds.contains(drink.id) {
                // 5 星：放入 3 次
                weightedPool.append(contentsOf: [drink, drink, drink])
            } else {
                // 4 星：放入 1 次
                weightedPool.append(drink)
            }
        }
        
        return weightedPool
    }
    
    /// 檢查是否有足夠資料進行智慧推薦
    func hasInsufficientData(logs: [DrinkLog]) -> Bool {
        return uniqueDrinkCount(from: logs) < minLogsForSmartRecommendation
    }
}
