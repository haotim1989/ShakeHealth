import SwiftUI

/// 分享服務
enum ShareService {
    /// 分享平台
    enum Platform: String, CaseIterable, Identifiable {
        case messenger = "Facebook Messenger"
        case line = "LINE"
        case slack = "Slack"
        
        var id: String { rawValue }
        
        var iconName: String {
            switch self {
            case .messenger: return "message.fill"
            case .line: return "bubble.left.fill"
            case .slack: return "number"
            }
        }
        
        var urlScheme: String {
            switch self {
            case .messenger: return "fb-messenger://"
            case .line: return "line://"
            case .slack: return "slack://"
            }
        }
    }
    
    /// 生成分享訊息
    static func generateShareMessage(for log: DrinkLog) -> String {
        let stars = String(repeating: "★", count: log.rating) + String(repeating: "☆", count: 5 - log.rating)
        let caffeineText = log.hasCaffeineSnapshot ? "☕ 含咖啡因" : "🌿 無咖啡因"
        
        var message = """
        🧋 我今天喝了【\(log.brandName) \(log.drinkName)】！
        
        📊 規格：\(log.selectedSugar.shortName) / \(log.selectedIce.rawValue)
        🔥 熱量：\(log.caloriesSnapshot) kcal
        \(caffeineText)
        ⭐ 評分：\(stars)
        """
        
        if !log.comment.isEmpty {
            message += "\n💬 感想：\(log.comment)"
        }
        
        message += """
        
        
        ---
        📱 用「搖搖健康飲」記錄你的飲料！
        👉 下載連結：\(Constants.AppStore.downloadURL)
        """
        
        return message
    }
    
    /// 分享到指定平台
    static func share(log: DrinkLog, to platform: Platform) {
        let message = generateShareMessage(for: log)
        let encodedMessage = message.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        
        var urlString: String
        
        switch platform {
        case .messenger:
            // Facebook Messenger 分享
            urlString = "fb-messenger://share?link=\(Constants.AppStore.downloadURL)&quote=\(encodedMessage)"
            
        case .line:
            // LINE 分享
            urlString = "line://msg/text/\(encodedMessage)"
            
        case .slack:
            // Slack 無法直接透過 URL Scheme 分享文字，使用系統分享
            shareViaSystem(message: message)
            return
        }
        
        guard let url = URL(string: urlString) else {
            // 若 URL 無效，使用系統分享
            shareViaSystem(message: message)
            return
        }
        
        // 檢查是否安裝了該 App
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
            HapticManager.shared.success()
        } else {
            // 未安裝該 App，使用系統分享
            shareViaSystem(message: message)
        }
    }
    
    /// 使用系統分享面板
    static func shareViaSystem(message: String) {
        let activityVC = UIActivityViewController(
            activityItems: [message],
            applicationActivities: nil
        )
        
        // 取得最上層的 ViewController
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            
            // 處理 iPad 的 popover
            if let popover = activityVC.popoverPresentationController {
                popover.sourceView = rootVC.view
                popover.sourceRect = CGRect(x: rootVC.view.bounds.midX, y: rootVC.view.bounds.midY, width: 0, height: 0)
                popover.permittedArrowDirections = []
            }
            
            rootVC.present(activityVC, animated: true)
            HapticManager.shared.light()
        }
    }
}
