import Foundation
import RevenueCat

/// RevenueCat 訂閱服務
/// 管理訂閱狀態、購買流程與 Offerings
@MainActor
final class SubscriptionService: NSObject, ObservableObject {
    static let shared = SubscriptionService()
    
    // MARK: - Published Properties
    
    /// RevenueCat Offerings (訂閱方案)
    @Published var offerings: Offerings?
    
    /// 當前客戶資訊
    @Published var customerInfo: CustomerInfo?
    
    /// 是否為 Pro 用戶
    @Published private(set) var isProUser: Bool = false
    
    /// 是否正在載入
    @Published var isLoading: Bool = false
    
    /// 是否已初始化
    @Published private(set) var isConfigured: Bool = false
    
    // MARK: - Entitlement ID
    
    /// Pro 權限 ID (需與 RevenueCat 後台設定一致)
    private let proEntitlementID = "pro"
    
    // MARK: - Initialization
    
    private override init() {
        super.init()
    }

    
    // MARK: - Configuration
    
    /// 初始化 RevenueCat SDK
    func configure() {
        guard let apiKey = SecretsManager.shared.revenueCatAPIKey, !apiKey.isEmpty else {
            print("⚠️ SubscriptionService: RevenueCat API Key 未設定，使用測試模式")
            isConfigured = false
            return
        }
        
        #if DEBUG
        Purchases.logLevel = .debug
        #endif
        
        Purchases.configure(withAPIKey: apiKey)
        
        // 設定代理監聽訂閱狀態變更
        Purchases.shared.delegate = self
        
        isConfigured = true
        print("✅ SubscriptionService: RevenueCat 已初始化")
        
        // 取得初始狀態
        Task {
            await fetchCustomerInfo()
            await fetchOfferings()
        }
    }
    
    // MARK: - Fetch Data
    
    /// 取得訂閱方案
    func fetchOfferings() async {
        guard isConfigured else {
            print("⚠️ SubscriptionService: 未初始化，無法取得 Offerings")
            return
        }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            self.offerings = try await Purchases.shared.offerings()
            print("✅ 已取得 Offerings: \(offerings?.current?.availablePackages.count ?? 0) 個方案")
        } catch {
            print("❌ 取得 Offerings 失敗: \(error.localizedDescription)")
        }
    }
    
    /// 取得客戶資訊
    func fetchCustomerInfo() async {
        guard isConfigured else {
            print("⚠️ SubscriptionService: 未初始化，無法取得 CustomerInfo")
            return
        }
        
        do {
            self.customerInfo = try await Purchases.shared.customerInfo()
            updateProStatus()
            print("✅ 已取得 CustomerInfo")
        } catch {
            print("❌ 取得 CustomerInfo 失敗: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Purchase
    
    /// 購買訂閱方案
    /// - Parameter package: RevenueCat Package
    /// - Returns: 購買結果
    func purchase(package: Package) async throws -> CustomerInfo {
        guard isConfigured else {
            throw SubscriptionError.notConfigured
        }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            let result = try await Purchases.shared.purchase(package: package)
            
            // 檢查是否被取消
            if result.userCancelled {
                throw SubscriptionError.userCancelled
            }
            
            self.customerInfo = result.customerInfo
            updateProStatus()
            
            print("✅ 購買成功: \(package.storeProduct.localizedTitle)")
            return result.customerInfo
        } catch let error as SubscriptionError {
            throw error
        } catch {
            print("❌ 購買失敗: \(error.localizedDescription)")
            throw SubscriptionError.purchaseFailed(error.localizedDescription)
        }
    }
    
    /// 恢復購買
    /// - Returns: 客戶資訊
    func restorePurchases() async throws -> CustomerInfo {
        guard isConfigured else {
            throw SubscriptionError.notConfigured
        }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            let customerInfo = try await Purchases.shared.restorePurchases()
            self.customerInfo = customerInfo
            updateProStatus()
            
            // 檢查是否有活躍的訂閱
            if !isProUser {
                throw SubscriptionError.noPurchasesToRestore
            }
            
            print("✅ 恢復購買成功")
            return customerInfo
        } catch let error as SubscriptionError {
            throw error
        } catch {
            print("❌ 恢復購買失敗: \(error.localizedDescription)")
            throw SubscriptionError.restoreFailed(error.localizedDescription)
        }
    }
    
    // MARK: - Private Methods
    
    private func updateProStatus() {
        let wasProUser = isProUser
        isProUser = customerInfo?.entitlements[proEntitlementID]?.isActive ?? false
        
        if wasProUser != isProUser {
            print("🔄 Pro 狀態更新: \(isProUser ? "啟用" : "停用")")
            
            // 追蹤用戶屬性
            AnalyticsService.shared.setUserProperty(
                value: isProUser ? "true" : "false",
                forName: .isPremium
            )
        }
    }
}

// MARK: - PurchasesDelegate

extension SubscriptionService: PurchasesDelegate {
    nonisolated func purchases(_ purchases: Purchases, receivedUpdated customerInfo: CustomerInfo) {
        Task { @MainActor in
            self.customerInfo = customerInfo
            self.updateProStatus()
        }
    }
}

// MARK: - Subscription Errors

enum SubscriptionError: LocalizedError {
    case notConfigured
    case userCancelled
    case purchaseFailed(String)
    case restoreFailed(String)
    case noPurchasesToRestore
    
    var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "訂閱服務尚未初始化"
        case .userCancelled:
            return "使用者取消購買"
        case .purchaseFailed(let message):
            return "購買失敗: \(message)"
        case .restoreFailed(let message):
            return "恢復購買失敗: \(message)"
        case .noPurchasesToRestore:
            return "找不到可恢復的購買紀錄"
        }
    }
}

// MARK: - Test Mode Support

extension SubscriptionService {
    /// 測試模式：切換 Pro 狀態
    /// 僅供開發測試使用
    func toggleProForTesting() {
        guard !isConfigured else {
            print("⚠️ 已連接 RevenueCat，無法使用測試模式")
            return
        }
        
        isProUser.toggle()
        print("🧪 測試模式：Pro 狀態切換為 \(isProUser)")
    }
    
    /// 測試模式：模擬購買成功
    func simulatePurchaseForTesting() async -> Bool {
        guard !isConfigured else {
            print("⚠️ 已連接 RevenueCat，無法使用測試模式")
            return false
        }
        
        // 模擬網路延遲
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        
        isProUser = true
        print("🧪 測試模式：模擬購買成功")
        return true
    }
}
