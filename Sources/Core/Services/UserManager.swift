import Foundation
import SwiftUI
import Combine

/// 用戶管理器 - 管理訂閱狀態與用戶偏好
/// 全域狀態，透過 @EnvironmentObject 注入所有 View
@MainActor
final class UserManager: ObservableObject {
    static let shared = UserManager()
    
    // MARK: - Published Properties
    
    /// 是否為 Pro 用戶
    @Published private(set) var isProUser: Bool = false
    
    /// 今日已記錄的日記數量
    @Published var todayLogCount: Int = 0
    
    /// 訂閱狀態描述
    @Published var subscriptionStatus: SubscriptionStatus = .free
    
    // MARK: - Private Properties
    
    private var cancellables = Set<AnyCancellable>()
    private let subscriptionService = SubscriptionService.shared
    private let adManager = AdManager.shared
    
    // MARK: - Subscription Status
    
    enum SubscriptionStatus: String {
        case free = "免費版"
        case pro = "Pro"
        case trial = "試用中"
    }
    
    // MARK: - Initialization
    
    private init() {
        setupSubscriptionBinding()
        loadTodayLogCount()
    }
    
    // MARK: - Setup
    
    private func setupSubscriptionBinding() {
        // 監聽 SubscriptionService 的 Pro 狀態變更
        subscriptionService.$isProUser
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isProUser in
                self?.isProUser = isProUser
                self?.subscriptionStatus = isProUser ? .pro : .free
                
                // 同步更新廣告顯示狀態
                self?.adManager.updateAdVisibility(isProUser: isProUser)
            }
            .store(in: &cancellables)
        
        // 如果 SubscriptionService 未初始化，使用測試模式
        if !subscriptionService.isConfigured {
            print("⚠️ UserManager: SubscriptionService 未初始化，使用測試模式")
            isProUser = false
            subscriptionStatus = .free
        }
    }
    
    private func loadTodayLogCount() {
        // 從 UserDefaults 載入今日記錄數
        let today = Calendar.current.startOfDay(for: Date())
        let lastResetDate = UserDefaults.standard.object(forKey: "lastDiaryResetDate") as? Date
        
        if let lastReset = lastResetDate, Calendar.current.isDate(lastReset, inSameDayAs: today) {
            // 同一天，載入計數
            todayLogCount = UserDefaults.standard.integer(forKey: "todayDiaryCount")
        } else {
            // 新的一天，重置計數
            resetDailyCount()
            UserDefaults.standard.set(today, forKey: "lastDiaryResetDate")
        }
    }
    
    // MARK: - Test Mode
    
    /// 切換 Pro 狀態 (僅供測試使用)
    func toggleProForTesting() {
        if subscriptionService.isConfigured {
            print("⚠️ 已連接 RevenueCat，請使用 Sandbox 測試購買")
            return
        }
        
        subscriptionService.toggleProForTesting()
    }
    
    // MARK: - Daily Limit Check
    
    /// 檢查是否可以新增日記 (免費版每日限制)
    func canAddDiaryEntry() -> Bool {
        if isProUser { return true }
        return todayLogCount < Constants.FeatureFlags.freeDailyDiaryLimit
    }
    
    /// 記錄新增日記
    func recordDiaryEntry() {
        todayLogCount += 1
        UserDefaults.standard.set(todayLogCount, forKey: "todayDiaryCount")
    }
    
    /// 重置每日計數 (應在每日午夜呼叫)
    func resetDailyCount() {
        todayLogCount = 0
        UserDefaults.standard.set(0, forKey: "todayDiaryCount")
    }
    
    // MARK: - Subscription Actions (Delegate to SubscriptionService)
    
    /// 檢查訂閱狀態
    func checkSubscriptionStatus() async {
        await subscriptionService.fetchCustomerInfo()
    }
    
    /// 恢復購買
    func restorePurchases() async -> Bool {
        do {
            _ = try await subscriptionService.restorePurchases()
            return true
        } catch {
            print("❌ 恢復購買失敗: \(error.localizedDescription)")
            return false
        }
    }
}

// MARK: - Subscription Packages (Fallback for UI)

/// 本地訂閱方案定義 (當 RevenueCat 未載入時使用)
enum SubscriptionPackage: String, CaseIterable, Identifiable {
    case monthly = "月訂閱"
    case yearly = "年訂閱"
    
    var id: String { rawValue }
    
    var price: String {
        switch self {
        case .monthly: return "NT$ 59"
        case .yearly: return "NT$ 499"
        }
    }
    
    var pricePerMonth: String {
        switch self {
        case .monthly: return "NT$ 59/月"
        case .yearly: return "NT$ 42/月"
        }
    }
    
    var savings: String? {
        switch self {
        case .monthly: return nil
        case .yearly: return "七折優惠！"
        }
    }
    
    var description: String {
        switch self {
        case .monthly: return "免費試用 7 天，一杯飲料換你整月健康"
        case .yearly: return "免費試用 7 天，每天$1.3 解鎖全部功能"
        }
    }
}
