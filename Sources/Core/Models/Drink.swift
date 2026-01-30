import Foundation

/// 飲品資料模型
struct Drink: Identifiable, Codable, Hashable {
    let id: String
    let brandId: String
    let name: String
    let category: DrinkCategory
    let imageURL: String?
    
    // 營養資訊
    let baseCalories: Int                     // 基礎熱量 (正常糖)
    let caloriesBySugar: [String: Int]?       // 各甜度對應熱量 (String key for Codable)
    let hasCaffeine: Bool
    let caffeineContent: Int?                 // mg (可選)
    
    // 可選配置
    let availableSugarLevels: [SugarLevel]
    let availableIceLevels: [IceLevel]
    
    init(
        id: String,
        brandId: String,
        name: String,
        category: DrinkCategory,
        imageURL: String? = nil,
        baseCalories: Int,
        caloriesBySugar: [SugarLevel: Int]? = nil,
        hasCaffeine: Bool,
        caffeineContent: Int? = nil,
        availableSugarLevels: [SugarLevel] = SugarLevel.allCases,
        availableIceLevels: [IceLevel] = IceLevel.allCases
    ) {
        self.id = id
        self.brandId = brandId
        self.name = name
        self.category = category
        self.imageURL = imageURL
        self.baseCalories = baseCalories
        // 轉換 SugarLevel key 為 String
        self.caloriesBySugar = caloriesBySugar?.reduce(into: [:]) { result, pair in
            result[pair.key.rawValue] = pair.value
        }
        self.hasCaffeine = hasCaffeine
        self.caffeineContent = caffeineContent
        self.availableSugarLevels = availableSugarLevels
        self.availableIceLevels = availableIceLevels
    }
    
    /// 根據甜度計算熱量
    func calories(for sugarLevel: SugarLevel) -> Int {
        if let calories = caloriesBySugar?[sugarLevel.rawValue] {
            return calories
        }
        // 若無特定數據，使用估算公式
        return Int(Double(baseCalories) * sugarLevel.multiplier)
    }
    
    /// 取得關聯品牌
    var brand: Brand? {
        Brand.find(byId: brandId)
    }
    
    // Firestore 欄位映射
    enum CodingKeys: String, CodingKey {
        case id = "drink_id"
        case brandId = "brand_id"
        case name
        case category
        case imageURL = "image_url"
        case baseCalories = "base_calories"
        case caloriesBySugar = "calories_by_sugar"
        case hasCaffeine = "has_caffeine"
        case caffeineContent = "caffeine_content"
        case availableSugarLevels = "available_sugar_levels"
        case availableIceLevels = "available_ice_levels"
    }
}

// MARK: - Sample Data
extension Drink {
    static let sampleDrinks: [Drink] = [
        // 50嵐
        Drink(
            id: "50lan_001",
            brandId: "50lan",
            name: "四季春青茶",
            category: .pureTea,
            baseCalories: 80,
            caloriesBySugar: [.sugar0: 5, .sugar30: 35, .sugar50: 50, .sugar70: 65, .sugar100: 80],
            hasCaffeine: true,
            caffeineContent: 50
        ),
        Drink(
            id: "50lan_002",
            brandId: "50lan",
            name: "波霸奶茶",
            category: .milkTea,
            baseCalories: 450,
            caloriesBySugar: [.sugar0: 280, .sugar30: 330, .sugar50: 380, .sugar70: 420, .sugar100: 450],
            hasCaffeine: true,
            caffeineContent: 80
        ),
        Drink(
            id: "50lan_003",
            brandId: "50lan",
            name: "檸檬綠茶",
            category: .fruitTea,
            baseCalories: 180,
            hasCaffeine: true,
            caffeineContent: 45
        ),
        
        // CoCo都可
        Drink(
            id: "coco_001",
            brandId: "coco",
            name: "珍珠奶茶",
            category: .milkTea,
            baseCalories: 480,
            caloriesBySugar: [.sugar0: 300, .sugar30: 350, .sugar50: 400, .sugar70: 450, .sugar100: 480],
            hasCaffeine: true,
            caffeineContent: 85
        ),
        Drink(
            id: "coco_002",
            brandId: "coco",
            name: "百香雙響炮",
            category: .fruitTea,
            baseCalories: 220,
            hasCaffeine: true,
            caffeineContent: 40
        ),
        Drink(
            id: "coco_003",
            brandId: "coco",
            name: "芒果冰沙",
            category: .special,
            baseCalories: 350,
            hasCaffeine: false
        ),
        
        // 迷客夏
        Drink(
            id: "milkshop_001",
            brandId: "milkshop",
            name: "大甲芋頭鮮奶",
            category: .fresh,
            baseCalories: 380,
            hasCaffeine: false,
            availableSugarLevels: [.sugar0, .sugar30, .sugar50]
        ),
        Drink(
            id: "milkshop_002",
            brandId: "milkshop",
            name: "厚奶茶",
            category: .milkTea,
            baseCalories: 320,
            caloriesBySugar: [.sugar0: 180, .sugar30: 220, .sugar50: 270, .sugar70: 300, .sugar100: 320],
            hasCaffeine: true,
            caffeineContent: 70
        ),
        Drink(
            id: "milkshop_003",
            brandId: "milkshop",
            name: "娜杯紅茶拿鐵",
            category: .milkTea,
            baseCalories: 290,
            hasCaffeine: true,
            caffeineContent: 65
        ),
        
        // 茶的魔手
        Drink(
            id: "teamagic_001",
            brandId: "teamagic",
            name: "高山青茶",
            category: .pureTea,
            baseCalories: 60,
            caloriesBySugar: [.sugar0: 0, .sugar30: 25, .sugar50: 40, .sugar70: 50, .sugar100: 60],
            hasCaffeine: true,
            caffeineContent: 55
        ),
        Drink(
            id: "teamagic_002",
            brandId: "teamagic",
            name: "冬瓜紅茶",
            category: .pureTea,
            baseCalories: 200,
            hasCaffeine: true,
            caffeineContent: 40,
            availableSugarLevels: [.sugar50, .sugar70, .sugar100] // 冬瓜糖無法去糖
        ),
        
        // 可不可熟成紅茶
        Drink(
            id: "kebuke_001",
            brandId: "kebuke",
            name: "熟成紅茶",
            category: .pureTea,
            baseCalories: 90,
            caloriesBySugar: [.sugar0: 0, .sugar30: 35, .sugar50: 55, .sugar70: 75, .sugar100: 90],
            hasCaffeine: true,
            caffeineContent: 60
        ),
        Drink(
            id: "kebuke_002",
            brandId: "kebuke",
            name: "熟成歐蕾",
            category: .milkTea,
            baseCalories: 280,
            hasCaffeine: true,
            caffeineContent: 55
        ),
        
        // 大苑子
        Drink(
            id: "dayun_001",
            brandId: "dayun",
            name: "鮮柚綠",
            category: .fruitTea,
            baseCalories: 150,
            hasCaffeine: true,
            caffeineContent: 35
        ),
        Drink(
            id: "dayun_002",
            brandId: "dayun",
            name: "芒果冰茶",
            category: .fruitTea,
            baseCalories: 250,
            hasCaffeine: true,
            caffeineContent: 30
        ),
    ]
}
