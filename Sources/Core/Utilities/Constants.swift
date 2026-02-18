import Foundation

/// 應用程式常數
enum Constants {
    /// Feature Flags - 功能開關
    enum FeatureFlags {
        /// 是否啟用訂閱功能
        static let subscriptionEnabled = true
        
        /// 是否啟用廣告
        static let adsEnabled = true
        
        /// 是否啟用 Interstitial 廣告
        static let interstitialAdsEnabled = true
        
        /// 插頁廣告觸發閾值 (每日第 N 次抽獎)
        static let interstitialPickThreshold = 3
        
        /// 免費用戶每日日記筆數限制
        static let freeDailyDiaryLimit = 1
    }
    
    /// 評論字數限制
    static let maxCommentLength = 30
    
    /// 動畫持續時間
    enum Animation {
        static let shakeAnimation: Double = 0.8
        static let cardAppear: Double = 0.3
        static let buttonPress: Double = 0.15
    }
    
    /// UserDefaults Keys
    enum StorageKeys {
        static let anonymousUserId = "anonymousUserId"
        static let lastFilterCriteria = "lastFilterCriteria"
        static let onboardingCompleted = "onboardingCompleted"
        static let dailyPickCount = "dailyPickCount"
        static let dailyPickDate = "dailyPickDate"
    }
    
    /// Google Maps
    enum Maps {
        static let googleMapsScheme = "comgooglemaps://"
        static let googleMapsWebURL = "https://www.google.com/maps/search/"
    }
    
    /// App Store (分享功能用)
    enum AppStore {
        static let appId = "id000000000"  // TODO: 替換為實際的 App ID
        static let downloadURL = "https://apps.apple.com/app/\(appId)"
        /// 管理訂閱 (iOS 設定頁面)
        static let manageSubscriptionURL = "https://apps.apple.com/account/subscriptions"
    }
    
    /// 法律相關連結
    enum Legal {
        // TODO: 替換為實際的隱私權政策與服務條款網址
        static let privacyPolicyURL = "https://example.com/privacy-policy"
        static let termsOfServiceURL = "https://example.com/terms-of-service"
    }
}
