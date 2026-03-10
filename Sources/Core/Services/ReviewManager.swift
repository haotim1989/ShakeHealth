import StoreKit

/// App Store 評價管理器
/// 在用戶首次成功完成第 3 筆日記時，跳出五星好評彈窗
@MainActor
final class ReviewManager {
    static let shared = ReviewManager()
    
    private let totalLogCountKey = "totalDiaryLogCount"
    private let hasRequestedReviewKey = "hasRequestedReview"
    
    private init() {}
    
    /// 記錄一次成功的日記儲存，並在第 3 筆時請求評價
    func trackDiarySave() {
        // 已經請求過就不再觸發
        guard !UserDefaults.standard.bool(forKey: hasRequestedReviewKey) else { return }
        
        let currentCount = UserDefaults.standard.integer(forKey: totalLogCountKey) + 1
        UserDefaults.standard.set(currentCount, forKey: totalLogCountKey)
        
        if currentCount >= 3 {
            requestReview()
            UserDefaults.standard.set(true, forKey: hasRequestedReviewKey)
        }
    }
    
    private func requestReview() {
        guard let windowScene = UIApplication.shared.connectedScenes
            .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene else {
            return
        }
        
        // 延遲 1 秒，讓儲存成功的 haptic 回饋結束後再跳
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            SKStoreReviewController.requestReview(in: windowScene)
        }
    }
}
