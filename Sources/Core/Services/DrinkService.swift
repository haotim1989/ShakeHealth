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
    
    private var isLoaded = false
    
    private init() {
        // 移除同步載入，改由 App 啟動時主動呼叫非同步的 loadDataAsync()
    }
    
    // MARK: - Async Data Loading
    
    /// 非同步載入大量 JSON 資料（用於啟動載入畫面 Splash Screen）
    func loadDataAsync() async {
        guard !isLoaded else { return }
        
        let result = await Task.detached(priority: .userInitiated) { () -> ([Drink]?, [Brand]?) in
            guard let url = Bundle.main.url(forResource: "SampleData", withExtension: "json") else {
                print("⚠️ 找不到 SampleData.json，使用備用資料")
                return (Drink.sampleDrinks, Brand.sampleBrands)
            }
            
            do {
                let data = try Data(contentsOf: url)
                let decoder = JSONDecoder()
                let sampleData = try decoder.decode(SampleDataContainer.self, from: data)
                
                let brands = sampleData.brands.map { brandData in
                    Brand(
                        id: brandData.brand_id,
                        name: brandData.brand_name,
                        logoURL: brandData.logo_url,
                        isActive: brandData.is_active
                    )
                }
                
                let sortedBrands = Brand.sorted(brands)
                
                let drinks = sampleData.drinks.map { drinkData in
                    Drink(
                        id: drinkData.drink_id,
                        brandId: drinkData.brand_id,
                        name: drinkData.name,
                        category: Self.refineCategory(name: drinkData.name, originalCategory: Self.mapCategory(drinkData.category)),
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
                
                return (drinks, sortedBrands)
            } catch {
                print("❌ 解析 SampleData.json 失敗: \(error)")
                return (Drink.sampleDrinks, Brand.sorted(Brand.sampleBrands))
            }
        }.value
        
        self.cachedDrinks = result.0
        self.cachedBrands = result.1
        self.isLoaded = true
        
        print("✅ 成功非同步載入 SampleData: \(self.cachedBrands?.count ?? 0) 品牌, \(self.cachedDrinks?.count ?? 0) 飲料")
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
    
    /// 根據飲料名稱關鍵字微調分類 (根據用戶優先度規則)
    static func refineCategory(name: String, originalCategory: DrinkCategory) -> DrinkCategory {
        // Priority 0: 咖啡 (優先歸類)
        let coffeeKeywords = ["拿鐵", "拿提", "拿堤", "咖啡", "瑪奇朵", "那提", "那堤"]
        if coffeeKeywords.contains(where: { name.contains($0) }) {
            return .coffee
        }
        
        // Priority 1.1: 特調
        let specialKeywords = ["星冰樂", "冰沙", "養樂多", "多多", "多", "冰淇淋", "阿華田"]
        if specialKeywords.contains(where: { name.contains($0) }) {
            return .special
        }
        
        // Priority 1.3: 原茶
        let pureTeaKeywords = ["觀音", "包種", "東方美人"]
        if pureTeaKeywords.contains(where: { name.contains($0) }) {
            return .pureTea
        }
        
        // Priority 1.4: 奶茶
        let milkTeaKeywords = ["乳茶"]
        if milkTeaKeywords.contains(where: { name.contains($0) }) {
            return .milkTea
        }
        
        return originalCategory
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
