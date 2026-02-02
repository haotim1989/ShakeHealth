import Foundation

/// 安全管理器 - 讀取敏感資訊 (API Keys)
/// 注意：Secrets.plist 不會被上傳到 Git
final class SecretsManager {
    static let shared = SecretsManager()
    
    private var secrets: [String: Any] = [:]
    
    /// 是否為測試模式 (找不到 Secrets.plist 時自動啟用)
    private(set) var isTestMode: Bool = true
    
    private init() {
        loadSecrets()
    }
    
    private func loadSecrets() {
        guard let path = Bundle.main.path(forResource: "Secrets", ofType: "plist"),
              let data = FileManager.default.contents(atPath: path),
              let plist = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any] else {
            print("⚠️ SecretsManager: Secrets.plist 不存在，使用測試模式")
            isTestMode = true
            return
        }
        
        secrets = plist
        isTestMode = false
        print("✅ SecretsManager: 已載入 Secrets.plist")
    }
    
    // MARK: - API Keys
    
    /// RevenueCat API Key
    var revenueCatAPIKey: String? {
        secrets["REVENUECAT_API_KEY"] as? String
    }
    
    /// AdMob App ID
    var adMobAppID: String? {
        secrets["ADMOB_APP_ID"] as? String
    }
    
    /// AdMob Banner Ad Unit ID
    var adMobBannerUnitID: String? {
        secrets["ADMOB_BANNER_UNIT_ID"] as? String
    }
    
    /// AdMob Native Ad Unit ID
    var adMobNativeUnitID: String? {
        secrets["ADMOB_NATIVE_UNIT_ID"] as? String
    }
}
