import UIKit

/// 觸覺回饋管理器
final class HapticManager {
    static let shared = HapticManager()
    
    private init() {}
    
    // MARK: - 基礎回饋
    
    /// 輕觸回饋
    func light() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
    
    /// 中等回饋
    func medium() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }
    
    /// 重度回饋
    func heavy() {
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.impactOccurred()
    }
    
    // MARK: - 通知回饋
    
    /// 成功回饋
    func success() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
    
    /// 警告回饋
    func warning() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.warning)
    }
    
    /// 錯誤回饋
    func error() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.error)
    }
    
    // MARK: - 自訂回饋
    
    /// 模擬搖飲料的震動效果
    func playShake() {
        Task {
            for i in 0..<6 {
                let intensity: UIImpactFeedbackGenerator.FeedbackStyle = i % 2 == 0 ? .heavy : .medium
                let generator = UIImpactFeedbackGenerator(style: intensity)
                generator.impactOccurred()
                try? await Task.sleep(nanoseconds: 80_000_000) // 80ms 間隔
            }
        }
    }
    
    /// 選擇項目時的回饋
    func selection() {
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
    }
}
