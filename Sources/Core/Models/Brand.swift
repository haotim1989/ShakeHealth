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
        Brand(id: "milksha", name: "迷客夏", logoURL: nil),
        Brand(id: "teamagic", name: "茶的魔手", logoURL: nil),
        Brand(id: "kebuke", name: "可不可熟成紅茶", logoURL: nil),
        Brand(id: "dayunzi", name: "大苑子", logoURL: nil),
        Brand(id: "qizhancha", name: "七盞茶", logoURL: nil),
        Brand(id: "qingxin", name: "清心福全", logoURL: nil),
        Brand(id: "ug", name: "UG", logoURL: nil),
        Brand(id: "comebuy", name: "COMEBUY", logoURL: nil),
        Brand(id: "wutonghao", name: "五桐號", logoURL: nil),
        Brand(id: "chatime", name: "Chatime 日出茶太", logoURL: nil),
        Brand(id: "shuixiang", name: "水巷茶弄", logoURL: nil),
        Brand(id: "xianhedao", name: "先喝道", logoURL: nil),
        Brand(id: "dezheng", name: "得正", logoURL: nil),
        Brand(id: "wanbo", name: "萬波島嶼紅茶", logoURL: nil),
        Brand(id: "guiji", name: "龜記茗品", logoURL: nil),
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
    
    /// 同步查找品牌 (優先使用 DrinkService 快取)
    static func find(byId id: String) -> Brand? {
        // 首先嘗試從 DrinkService 快取查找
        if let brands = DrinkService.shared.getCachedBrands() {
            return brands.first { $0.id == id }
        }
        // 備用：使用 sampleBrands
        return sampleBrands.first { $0.id == id }
    }
}

