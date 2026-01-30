import Foundation
import SwiftData

/// 飲料日記紀錄 (本地儲存使用 SwiftData)
@Model
final class DrinkLog {
    var id: String
    var drinkId: String
    var brandId: String
    var userId: String
    
    // 選擇的規格
    var selectedSugarRaw: String
    var selectedIceRaw: String
    
    // 評價
    var rating: Int      // 1-5
    var comment: String  // 限制 20 字
    
    // 快照資料 (記錄當下的飲料資訊)
    var drinkName: String
    var brandName: String
    var caloriesSnapshot: Int
    
    var createdAt: Date
    var updatedAt: Date
    
    // MARK: - Computed Properties
    
    var selectedSugar: SugarLevel {
        get { SugarLevel(rawValue: selectedSugarRaw) ?? .sugar100 }
        set { selectedSugarRaw = newValue.rawValue }
    }
    
    var selectedIce: IceLevel {
        get { IceLevel(rawValue: selectedIceRaw) ?? .normalIce }
        set { selectedIceRaw = newValue.rawValue }
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
            "created_at": createdAt,
            "updated_at": updatedAt
        ]
    }
}
