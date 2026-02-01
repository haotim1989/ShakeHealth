import Foundation

/// 品牌資料模型
struct Brand: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let logoURL: String?
    let isActive: Bool
    
    init(id: String, name: String, logoURL: String? = nil, isActive: Bool = true) {
        self.id = id
        self.name = name
        self.logoURL = logoURL
        self.isActive = isActive
    }
    
    // Firestore 欄位映射
    enum CodingKeys: String, CodingKey {
        case id = "brand_id"
        case name = "brand_name"
        case logoURL = "logo_url"
        case isActive = "is_active"
    }
}

// MARK: - Sample Data
extension Brand {
    static let sampleBrands: [Brand] = [
        Brand(id: "50lan", name: "50嵐", logoURL: nil),
        Brand(id: "coco", name: "CoCo都可", logoURL: nil),
        Brand(id: "milkshop", name: "迷客夏", logoURL: nil),
        Brand(id: "teamagic", name: "茶的魔手", logoURL: nil),
        Brand(id: "kebuke", name: "可不可熟成紅茶", logoURL: nil),
        Brand(id: "dayun", name: "大苑子", logoURL: nil),
    ]
    
    /// 所有品牌 (優先從 DrinkService 取得)
    static var allBrands: [Brand] {
        get async {
            do {
                return try await DrinkService.shared.fetchAllBrands()
            } catch {
                return sampleBrands
            }
        }
    }
    
    static func find(byId id: String) -> Brand? {
        // 同步查找，使用備用資料
        sampleBrands.first { $0.id == id }
    }
}
