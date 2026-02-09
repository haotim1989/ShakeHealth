import SwiftUI

/// 分享服務
@MainActor
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
    }
    
    // MARK: - App 分享
    
    /// 分享 App (包含圖片與文字)
    static func shareApp() {
        let text = """
        🧋 飲料日記 - 記錄你的飲料生活
        
        追蹤每日飲料攝取、熱量與咖啡因，讓你喝得更健康！
        
        📲 立即下載：\(Constants.AppStore.downloadURL)
        """
        
        // 生成推廣圖片
        let image = generateAppPromoImage()
        
        // 準備分享項目
        var items: [Any] = [text]
        if let image = image {
            items.append(image)
        }
        
        shareViaSystem(items: items)
    }
    
    /// 生成 App 推廣圖片
    static func generateAppPromoImage() -> UIImage? {
        let view = AppPromoCard()
        let renderer = ImageRenderer(content: view)
        renderer.scale = UIScreen.main.scale
        return renderer.uiImage
    }
    
    // MARK: - 日記分享
    
    /// 生成日記分享訊息
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
        📱 用「搖搖健康飲」記錄你的飲料生活！
        👉 下載連結：\(Constants.AppStore.downloadURL)
        """
        
        return message
    }
    
    /// 分享日記 (文字)
    static func share(log: DrinkLog) {
        let message = generateShareMessage(for: log)
        shareViaSystem(items: [message])
    }
    
    // MARK: - Helper
    
    /// 使用系統分享面板
    private static func shareViaSystem(items: [Any]) {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootVC = windowScene.windows.first?.rootViewController else { return }
        
        let activityVC = UIActivityViewController(
            activityItems: items,
            applicationActivities: nil
        )
        
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

// MARK: - Views

/// App 推廣小卡 (用於生成圖片)
struct AppPromoCard: View {
    var body: some View {
        ZStack {
            Color.milkCream
            
            VStack(spacing: 20) {
                // Icon
                ZStack {
                    Circle()
                        .fill(Color.teaBrown)
                        .frame(width: 120, height: 120)
                    
                    Image(systemName: "cup.and.saucer.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.white)
                }
                .shadow(color: .black.opacity(0.1), radius: 10, y: 5)
                
                VStack(spacing: 8) {
                    Text("飲料日記")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.teaBrown)
                    
                    Text("ShakeHealth")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.teaBrown.opacity(0.8))
                }
                
                Text("記錄每一杯\n療癒時刻")
                    .font(.system(size: 24))
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding(.top, 10)
                
                // Bottom
                HStack(spacing: 6) {
                    Image(systemName: "arrow.down.circle.fill")
                    Text("App Store 下載")
                }
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.teaBrown)
                .clipShape(Capsule())
                .padding(.top, 20)
            }
            .padding(40)
        }
        .frame(width: 400, height: 500)
    }
}
