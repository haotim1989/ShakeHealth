import Foundation

/// 飲料資料服務
protocol DrinkServiceProtocol {
    func fetchAllDrinks() async throws -> [Drink]
    func fetchDrinks(for brandId: String) async throws -> [Drink]
    func searchDrinks(query: String) async throws -> [Drink]
    func fetchAllBrands() async throws -> [Brand]
}

/// 飲料資料服務實作 (使用 SampleData.json)
final class DrinkService: DrinkServiceProtocol {
    static let shared = DrinkService()
    
    // 快取資料
    private var cachedDrinks: [Drink]?
    private var cachedBrands: [Brand]?
    
    private init() {
        loadDataFromJSON()
    }
    
    // MARK: - JSON 載入
    
    private func loadDataFromJSON() {
        guard let url = Bundle.main.url(forResource: "SampleData", withExtension: "json") else {
            print("⚠️ 找不到 SampleData.json，使用備用資料")
            cachedDrinks = Drink.sampleDrinks
            cachedBrands = Brand.sampleBrands
            return
        }
        
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            let sampleData = try decoder.decode(SampleDataContainer.self, from: data)
            
            // 將 Brand 資料轉換並快取
            let brands = sampleData.brands.map { brandData in
                Brand(
                    id: brandData.brand_id,
                    name: brandData.brand_name,
                    logoURL: brandData.logo_url,
                    isActive: brandData.is_active
                )
            }
            
            
            // 排序邏輯：數字 -> 英文 -> 中文 (筆畫)
            cachedBrands = Brand.sorted(brands)
            
            // 將 Drink 資料轉換並快取
            cachedDrinks = sampleData.drinks.map { drinkData in
                Drink(
                    id: drinkData.drink_id,
                    brandId: drinkData.brand_id,
                    name: drinkData.name,
                    category: Self.mapCategory(drinkData.category),
                    imageURL: drinkData.image_url,
                    baseCalories: drinkData.base_calories,
                    caloriesBySugar: nil,
                    sugarGrams: drinkData.sugar_grams,
                    hasCaffeine: drinkData.has_caffeine,
                    caffeineContent: drinkData.caffeine_content,
                    availableSugarLevels: SugarLevel.allCases,
                    availableIceLevels: IceLevel.allCases
                )
            }
            
            print("✅ 成功載入 SampleData.json: \(cachedBrands?.count ?? 0) 品牌, \(cachedDrinks?.count ?? 0) 飲料")
            
        } catch {
            print("❌ 解析 SampleData.json 失敗: \(error)")
            cachedDrinks = Drink.sampleDrinks
            cachedBrands = Brand.sorted(Brand.sampleBrands)
        }
    }
    
    // MARK: - Category Mapping
    
    /// 將英文分類 key 轉換為 DrinkCategory
    private static func mapCategory(_ key: String) -> DrinkCategory {
        switch key {
        case "milkTea": return .milkTea
        case "pureTea": return .pureTea
        case "fruitTea": return .fruitTea
        case "coffee": return .coffee
        case "fresh": return .fresh
        case "special": return .special
        default: return .special
        }
    }
    
    // MARK: - Protocol Methods
    
    func fetchAllDrinks() async throws -> [Drink] {
        try? await Task.sleep(nanoseconds: 100_000_000)
        return cachedDrinks ?? Drink.sampleDrinks
    }
    
    func fetchDrinks(for brandId: String) async throws -> [Drink] {
        let drinks = cachedDrinks ?? Drink.sampleDrinks
        return drinks.filter { $0.brandId == brandId }
    }
    
    func searchDrinks(query: String) async throws -> [Drink] {
        let drinks = cachedDrinks ?? Drink.sampleDrinks
        guard !query.isEmpty else { return drinks }
        
        let lowercasedQuery = query.lowercased()
        return drinks.filter { drink in
            drink.name.lowercased().contains(lowercasedQuery) ||
            (drink.brand?.name.lowercased().contains(lowercasedQuery) ?? false)
        }
    }
    
    func fetchAllBrands() async throws -> [Brand] {
        return cachedBrands ?? Brand.sorted(Brand.sampleBrands)
    }
    
    /// 同步取得快取的品牌資料 (供 Brand.find 使用)
    func getCachedBrands() -> [Brand]? {
        return cachedBrands
    }
    
    /// 根據 ID 取得飲料
    func getDrink(byId drinkId: String) -> Drink? {
        return cachedDrinks?.first { $0.id == drinkId }
    }
}

// MARK: - JSON Data Structures

private struct SampleDataContainer: Decodable {
    let brands: [BrandData]
    let drinks: [DrinkData]
}

private struct BrandData: Decodable {
    let brand_id: String
    let brand_name: String
    let logo_url: String?
    let is_active: Bool
}

private struct DrinkData: Decodable {
    let drink_id: String
    let brand_id: String
    let name: String
    let category: String
    let image_url: String?
    let base_calories: Int
    let sugar_grams: Double?
    let has_caffeine: Bool?
    let caffeine_content: Int?
    let available_sugar_levels: [String]?
    let available_ice_levels: [String]?
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
