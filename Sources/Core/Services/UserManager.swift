import Foundation
import SwiftUI

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
    
    // MARK: - Subscription Status
    
    enum SubscriptionStatus: String {
        case free = "免費版"
        case pro = "Pro"
        case trial = "試用中"
    }
    
    // MARK: - Initialization
    
    private init() {
        // 檢查是否為測試模式
        if SecretsManager.shared.isTestMode {
            print("⚠️ UserManager: 測試模式 - 訂閱功能使用 Mock")
            setupTestMode()
        } else {
            checkSubscriptionStatus()
        }
    }
    
    // MARK: - Test Mode (Mock)
    
    private func setupTestMode() {
        // 測試模式：預設為免費用戶
        isProUser = false
        subscriptionStatus = .free
    }
    
    /// 切換 Pro 狀態 (僅供測試使用)
    func toggleProForTesting() {
        isProUser.toggle()
        subscriptionStatus = isProUser ? .pro : .free
        print("🧪 測試模式：Pro 狀態切換為 \(isProUser)")
    }
    
    // MARK: - RevenueCat Integration (待實作)
    
    /// 檢查訂閱狀態
    func checkSubscriptionStatus() {
        // TODO: 待 RevenueCat 帳號建立後實作
        // Purchases.shared.getCustomerInfo { customerInfo, error in
        //     self.isProUser = customerInfo?.entitlements["pro"]?.isActive ?? false
        // }
        
        // 目前使用 Mock
        isProUser = false
        subscriptionStatus = .free
    }
    
    /// 購買訂閱 (Mock)
    func purchaseSubscription(package: SubscriptionPackage) async -> Bool {
        // TODO: 待 RevenueCat 帳號建立後實作
        print("📦 模擬購買: \(package.rawValue)")
        
        // Mock: 模擬成功購買
        if SecretsManager.shared.isTestMode {
            isProUser = true
            subscriptionStatus = .pro
            return true
        }
        
        return false
    }
    
    /// 恢復購買 (Mock)
    func restorePurchases() async -> Bool {
        // TODO: 待 RevenueCat 帳號建立後實作
        print("🔄 模擬恢復購買")
        return false
    }
    
    // MARK: - Daily Limit Check
    
    /// 檢查是否可以新增日記 (免費版每日 1 筆限制)
    func canAddDiaryEntry() -> Bool {
        if isProUser { return true }
        return todayLogCount < 1
    }
    
    /// 記錄新增日記
    func recordDiaryEntry() {
        todayLogCount += 1
    }
    
    /// 重置每日計數 (應在每日午夜呼叫)
    func resetDailyCount() {
        todayLogCount = 0
    }
}

// MARK: - Subscription Packages

enum SubscriptionPackage: String, CaseIterable, Identifiable {
    case monthly = "月訂閱"
    case yearly = "年訂閱"
    
    var id: String { rawValue }
    
    var price: String {
        switch self {
        case .monthly: return "NT$ 49"
        case .yearly: return "NT$ 499"
        }
    }
    
    var pricePerMonth: String {
        switch self {
        case .monthly: return "NT$ 49/月"
        case .yearly: return "NT$ 42/月"
        }
    }
    
    var savings: String? {
        switch self {
        case .monthly: return nil
        case .yearly: return "省 NT$ 89"
        }
    }
    
    var description: String {
        switch self {
        case .monthly: return "按月付費，隨時取消"
        case .yearly: return "年繳最划算，相當於 10 個月價格"
        }
    }
}
