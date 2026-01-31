import Foundation

/// 應用程式常數
enum Constants {
    /// 評論字數限制
    static let maxCommentLength = 20
    
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
    }
}
