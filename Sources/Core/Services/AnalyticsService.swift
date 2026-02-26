import Foundation

#if canImport(FirebaseAnalytics)
import FirebaseAnalytics
#endif

/// 分析事件追蹤服務
/// 封裝 Firebase Analytics，提供強型別的事件名稱與參數
final class AnalyticsService {
    static let shared = AnalyticsService()
    
    private init() {}
    
    // MARK: - Core Functions
    
    /// 記錄事件
    /// - Parameters:
    ///   - event: 事件名稱 (使用預定義的 Event enum)
    ///   - parameters: 額外參數
    func logEvent(_ event: AnalyticsEvent, parameters: [String: Any]? = nil) {
        #if canImport(FirebaseAnalytics)
        Analytics.logEvent(event.rawValue, parameters: parameters)
        print("📊 [Analytics] logged event: \(event.rawValue) | params: \(parameters ?? [:])")
        #else
        print("📊 [Analytics Mock] event: \(event.rawValue) | params: \(parameters ?? [:])")
        #endif
    }
    
    /// 設定用戶屬性
    /// - Parameters:
    ///   - value: 屬性值
    ///   - property: 屬性名稱
    func setUserProperty(value: String?, forName property: UserProperty) {
        #if canImport(FirebaseAnalytics)
        Analytics.setUserProperty(value, forName: property.rawValue)
        print("👤 [Analytics] set user property: \(property.rawValue) = \(value ?? "nil")")
        #else
        print("👤 [Analytics Mock] set user property: \(property.rawValue) = \(value ?? "nil")")
        #endif
    }
}

// MARK: - Event Definitions

extension AnalyticsService {
    
    /// 預定義的事件名稱字典
    enum AnalyticsEvent: String {
        // Core Action
        case diaryAddClick = "diary_add_click"
        case diarySaveSuccess = "diary_save_success"
        case diarySaveCancel = "diary_save_cancel"
        
        // Random Drink Feature
        case randomPickerView = "random_picker_view"
        case randomPickerRoll = "random_picker_roll"
        case randomPickerFilterApply = "random_picker_filter_apply"
        case randomPickerResultAction = "random_picker_result_action"
        
        // Monetization
        case paywallView = "paywall_view"
        case paywallPackageSelect = "paywall_package_select"
        case paywallPurchaseStart = "paywall_purchase_start"
        case paywallRestoreClick = "paywall_restore_click"
        
        // Engagement
        case monthlyReportView = "monthly_report_view"
        case appShareClick = "app_share_click"
        case dataExportCSV = "data_export_csv"
    }
    
    /// 預定義的用戶屬性
    enum UserProperty: String {
        case isPremium = "is_premium"
        case drinkLogCount = "drink_log_count"
    }
    
    /// 預定義的參數 Keys
    enum ParamKey {
        static let source = "source"
        static let isCustom = "is_custom"
        static let hasComment = "has_comment"
        static let rating = "rating"
        static let step = "step"
        static let triggerType = "trigger_type"
        static let hasBrandFilter = "has_brand_filter"
        static let hasCategoryFilter = "has_category_filter"
        static let smartRecommendOn = "smart_recommend_on"
        static let action = "action"
        static let packageType = "package_type"
        static let totalSugar = "total_sugar"
        static let shareType = "share_type"
        static let logCount = "log_count"
    }
}
