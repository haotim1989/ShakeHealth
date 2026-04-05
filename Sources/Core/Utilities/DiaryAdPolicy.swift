import Foundation

/// 日記儲存廣告分級策略
/// 根據用戶累積日記總數，決定每天第幾次儲存開始跳插頁廣告
enum DiaryAdPolicy {
    /// 回傳今天第幾次儲存才開始跳廣告
    /// 回傳 nil 表示不跳廣告（新用戶保護）
    static func dailyAdThreshold(totalLogCount: Int) -> Int? {
        if totalLogCount >= Constants.FeatureFlags.diaryAdTier2Threshold { return 1 }
        if totalLogCount >= Constants.FeatureFlags.diaryAdTier1Threshold { return 2 }
        return nil
    }
}
