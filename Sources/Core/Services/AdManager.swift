import Foundation
import GoogleMobileAds
import AppTrackingTransparency

/// Google AdMob 廣告管理器
/// 管理廣告 SDK 初始化、ATT 授權與廣告單元 ID
@MainActor
final class AdManager: ObservableObject {
    static let shared = AdManager()
    
    // MARK: - Published Properties
    
    /// SDK 是否已初始化
    @Published private(set) var isInitialized: Bool = false
    
    /// 追蹤授權狀態
    @Published private(set) var trackingAuthorizationStatus: ATTrackingManager.AuthorizationStatus = .notDetermined
    
    /// 是否應該顯示廣告
    @Published private(set) var shouldShowAds: Bool = true
    
    // MARK: - Initialization
    
    private init() {}
    
    // MARK: - Configuration
    
    /// 初始化 AdMob SDK
    func configure() {
        // 檢查是否啟用廣告
        guard Constants.FeatureFlags.adsEnabled else {
            print("⚠️ AdManager: 廣告功能已停用")
            shouldShowAds = false
            return
        }
        
        MobileAds.shared.start { [weak self] status in
            Task { @MainActor in
                self?.isInitialized = true
                
                // 列印各 adapter 狀態
                let adapterStatuses = status.adapterStatusesByClassName
                for (className, adapterStatus) in adapterStatuses {
                    print("📱 AdMob Adapter: \(className) - \(adapterStatus.state.rawValue)")
                }
                
                print("✅ AdMob SDK 初始化完成")
            }
        }
    }
    
    // MARK: - ATT (App Tracking Transparency)
    
    /// 請求 ATT 追蹤授權
    /// 應在 App 啟動後適當時機呼叫
    func requestTrackingAuthorization() async {
        // iOS 14+ 需要請求追蹤授權
        guard #available(iOS 14.0, *) else {
            trackingAuthorizationStatus = .authorized
            return
        }
        
        // 檢查目前狀態
        let currentStatus = ATTrackingManager.trackingAuthorizationStatus
        
        if currentStatus == .notDetermined {
            // 尚未決定，請求授權
            let status = await ATTrackingManager.requestTrackingAuthorization()
            trackingAuthorizationStatus = status
            
            switch status {
            case .authorized:
                print("✅ ATT: 使用者同意追蹤")
            case .denied:
                print("⚠️ ATT: 使用者拒絕追蹤")
            case .restricted:
                print("⚠️ ATT: 追蹤受限")
            case .notDetermined:
                print("⚠️ ATT: 狀態未決定")
            @unknown default:
                print("⚠️ ATT: 未知狀態")
            }
        } else {
            trackingAuthorizationStatus = currentStatus
        }
    }
    
    // MARK: - Ad Unit IDs
    
    /// Banner 廣告單元 ID
    var bannerAdUnitID: String {
        // 優先使用 Secrets 中的設定，否則使用 Google 測試 ID
        if let customID = SecretsManager.shared.adMobBannerUnitID, !customID.isEmpty {
            return customID
        }
        // Google 官方測試 Banner ID
        return "ca-app-pub-3940256099942544/2934735716"
    }
    
    /// Native 廣告單元 ID
    var nativeAdUnitID: String {
        if let customID = SecretsManager.shared.adMobNativeUnitID, !customID.isEmpty {
            return customID
        }
        // Google 官方測試 Native ID
        return "ca-app-pub-3940256099942544/3986624511"
    }
    
    /// Interstitial 廣告單元 ID
    var interstitialAdUnitID: String {
        // Google 官方測試 Interstitial ID
        return "ca-app-pub-3940256099942544/4411468910"
    }
    
    // MARK: - Ad Visibility Control
    
    /// 更新廣告顯示狀態
    /// - Parameter isProUser: 使用者是否為 Pro
    func updateAdVisibility(isProUser: Bool) {
        shouldShowAds = Constants.FeatureFlags.adsEnabled && !isProUser
    }
}

// MARK: - UIApplication Extension

extension UIApplication {
    /// 取得根視圖控制器 (用於廣告展示)
    var rootViewController: UIViewController? {
        guard let windowScene = connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            return nil
        }
        return window.rootViewController
    }
}
