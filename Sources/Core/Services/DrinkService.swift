import Foundation

/// 飲料資料服務
protocol DrinkServiceProtocol {
    func fetchAllDrinks() async throws -> [Drink]
    func fetchDrinks(for brandId: String) async throws -> [Drink]
    func searchDrinks(query: String) async throws -> [Drink]
    func fetchAllBrands() async throws -> [Brand]
}

/// 飲料資料服務實作 (使用本地 Sample Data)
final class DrinkService: DrinkServiceProtocol {
    static let shared = DrinkService()
    
    private init() {}
    
    func fetchAllDrinks() async throws -> [Drink] {
        // 模擬網路延遲
        try? await Task.sleep(nanoseconds: 300_000_000)
        return Drink.sampleDrinks
    }
    
    func fetchDrinks(for brandId: String) async throws -> [Drink] {
        try? await Task.sleep(nanoseconds: 200_000_000)
        return Drink.sampleDrinks.filter { $0.brandId == brandId }
    }
    
    func searchDrinks(query: String) async throws -> [Drink] {
        guard !query.isEmpty else { return Drink.sampleDrinks }
        
        let lowercasedQuery = query.lowercased()
        return Drink.sampleDrinks.filter { drink in
            drink.name.lowercased().contains(lowercasedQuery) ||
            (drink.brand?.name.lowercased().contains(lowercasedQuery) ?? false)
        }
    }
    
    func fetchAllBrands() async throws -> [Brand] {
        try? await Task.sleep(nanoseconds: 200_000_000)
        return Brand.sampleBrands
    }
}

// MARK: - Errors
enum DrinkServiceError: LocalizedError {
    case fetchFailed
    case notFound
    
    var errorDescription: String? {
        switch self {
        case .fetchFailed: return "無法載入飲料資料"
        case .notFound: return "找不到指定的飲料"
        }
    }
}
