import Foundation
import SwiftData

/// 飲料日記紀錄 (本地儲存使用 SwiftData)
@Model
final class DrinkLog {
    var id: String = UUID().uuidString
    var drinkId: String = ""
    var brandId: String = ""
    var userId: String = ""
    
    // 選擇的規格
    var selectedSugarRaw: String = ""
    var selectedIceRaw: String = ""
    
    // 評價
    var rating: Int = 0      // 1-5
    var comment: String = "" // 限制 20 字
    
    // 快照資料 (記錄當下的飲料資訊)
    var drinkName: String = ""
    var brandName: String = ""
    var caloriesSnapshot: Int = 0
    var hasCaffeineSnapshot: Bool = false
    var sugarSnapshot: Double?   // 新增：糖分快照 (克)
    var caffeineSnapshot: Int?   // 新增：咖啡因快照 (毫克)
    var toppingsSnapshot: String = ""  // 配料快照（逗號分隔 rawValue）
    
    // 口感風味評鑑（選填）
    var tasteTexture: String = ""     // 配料口感
    var tasteTea: String = ""         // 茶味
    var tasteMilk: String = ""        // 奶味
    var tasteSweetness: String = ""   // 甜度感受
    var tasteIce: String = ""         // 冰塊感受
    var tasteSmoothness: String = ""  // 順口度
    var tasteAroma: String = ""       // 香氣
    
    // 消費體驗（選填）
    var expCostPerformance: String = ""  // CP 值
    var expOccasion: String = ""          // 飲用情境
    var expRepurchase: String = ""        // 再回購
    var expPortion: String = ""           // 份量
    var expWaitTime: String = ""          // 等待時長
    
    // 價格（選填，單位：新台幣）
    var price: Int?
    
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
    
    // MARK: - Computed Properties
    
    var selectedSugar: SugarLevel {
        get { SugarLevel(rawValue: selectedSugarRaw) ?? .sugar100 }
        set { selectedSugarRaw = newValue.rawValue }
    }
    
    var selectedIce: IceLevel {
        get {
            if let level = IceLevel(rawValue: selectedIceRaw) {
                return level
            }
            // 向下相容：舊版 rawValue 映射
            switch selectedIceRaw {
            case "熱飲": return .hot
            default: return .normalIce
            }
        }
        set { selectedIceRaw = newValue.rawValue }
    }
    
    /// 取得飲料分類 (如果找不到原始飲料資料，則回傳 .custom)
    var category: DrinkCategory {
        if let drink = DrinkService.shared.getDrink(byId: drinkId) {
            return drink.category
        }
        return DrinkService.refineCategory(name: drinkName, originalCategory: .custom)
    }
    
    /// 已選配料
    var selectedToppings: Set<Topping> {
        Topping.deserialize(toppingsSnapshot)
    }
    
    /// 配料總熱量
    var toppingsCalories: Int {
        Topping.totalCalories(selectedToppings)
    }
    
    // MARK: - Initializer
    
    init(
        id: String = UUID().uuidString,
        drinkId: String,
        brandId: String,
        userId: String,
        selectedSugar: SugarLevel,
        selectedIce: IceLevel,
        rating: Int,
        comment: String,
        drinkName: String,
        brandName: String,
        caloriesSnapshot: Int,
        hasCaffeineSnapshot: Bool = false,
        sugarSnapshot: Double? = nil,
        caffeineSnapshot: Int? = nil,
        toppingsSnapshot: String = "",
        tasteTexture: String = "",
        tasteTea: String = "",
        tasteMilk: String = "",
        tasteSweetness: String = "",
        tasteIce: String = "",
        tasteSmoothness: String = "",
        tasteAroma: String = "",
        expCostPerformance: String = "",
        expOccasion: String = "",
        expRepurchase: String = "",
        expPortion: String = "",
        expWaitTime: String = "",
        price: Int? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.drinkId = drinkId
        self.brandId = brandId
        self.userId = userId
        self.selectedSugarRaw = selectedSugar.rawValue
        self.selectedIceRaw = selectedIce.rawValue
        self.rating = rating
        self.comment = comment
        self.drinkName = drinkName
        self.brandName = brandName
        self.caloriesSnapshot = caloriesSnapshot
        self.hasCaffeineSnapshot = hasCaffeineSnapshot
        self.sugarSnapshot = sugarSnapshot
        self.caffeineSnapshot = caffeineSnapshot
        self.toppingsSnapshot = toppingsSnapshot
        self.tasteTexture = tasteTexture
        self.tasteTea = tasteTea
        self.tasteMilk = tasteMilk
        self.tasteSweetness = tasteSweetness
        self.tasteIce = tasteIce
        self.tasteSmoothness = tasteSmoothness
        self.tasteAroma = tasteAroma
        self.expCostPerformance = expCostPerformance
        self.expOccasion = expOccasion
        self.expRepurchase = expRepurchase
        self.expPortion = expPortion
        self.expWaitTime = expWaitTime
        self.price = price
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    // MARK: - Validation
    
    /// 驗證評論字數
    static func validateComment(_ comment: String) -> Bool {
        comment.count <= 20
    }
    
    /// 驗證評分範圍
    static func validateRating(_ rating: Int) -> Bool {
        (1...5).contains(rating)
    }
}

// MARK: - Firestore Codable Support (未來擴充)
extension DrinkLog {
    /// 轉換為可上傳至 Firestore 的字典
    func toFirestoreData() -> [String: Any] {
        return [
            "log_id": id,
            "drink_id": drinkId,
            "brand_id": brandId,
            "user_id": userId,
            "selected_sugar": selectedSugarRaw,
            "selected_ice": selectedIceRaw,
            "rating": rating,
            "comment": comment,
            "drink_name_snapshot": drinkName,
            "brand_name_snapshot": brandName,
            "calories_snapshot": caloriesSnapshot,
            "has_caffeine_snapshot": hasCaffeineSnapshot,
            "sugar_snapshot": sugarSnapshot ?? NSNull(),
            "caffeine_snapshot": caffeineSnapshot ?? NSNull(),
            "toppings_snapshot": toppingsSnapshot,
            "taste_texture": tasteTexture,
            "taste_tea": tasteTea,
            "taste_milk": tasteMilk,
            "taste_sweetness": tasteSweetness,
            "taste_ice": tasteIce,
            "taste_smoothness": tasteSmoothness,
            "taste_aroma": tasteAroma,
            "exp_cost_performance": expCostPerformance,
            "exp_occasion": expOccasion,
            "exp_repurchase": expRepurchase,
            "exp_portion": expPortion,
            "exp_wait_time": expWaitTime,
            "price": price ?? NSNull(),
            "created_at": createdAt,
            "updated_at": updatedAt
        ]
    }
}
