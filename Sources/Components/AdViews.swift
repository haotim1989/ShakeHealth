import SwiftUI

/// 橫幅廣告視圖 (Mock)
/// 待 AdMob 帳號建立後替換為真實廣告
struct BannerAdView: View {
    @EnvironmentObject var userManager: UserManager
    
    var body: some View {
        // Pro 用戶不顯示廣告
        if !userManager.isProUser {
            bannerContent
        }
    }
    
    private var bannerContent: some View {
        ZStack {
            // Mock 廣告背景
            Rectangle()
                .fill(Color.gray.opacity(0.1))
                .frame(height: 50)
            
            HStack {
                Image(systemName: "megaphone.fill")
                    .foregroundColor(.secondary)
                
                if SecretsManager.shared.isTestMode {
                    Text("廣告區域 (測試模式)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else {
                    // TODO: 替換為真實 AdMob Banner
                    Text("廣告載入中...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // 升級 Pro 按鈕
                Button {
                    // 觸發 Paywall
                } label: {
                    Text("移除廣告")
                        .font(.caption2)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.teaBrown)
                        .foregroundColor(.white)
                        .clipShape(Capsule())
                }
            }
            .padding(.horizontal)
        }
    }
}

/// 原生廣告視圖 (Mock)
/// 用於圖鑑列表中每 10 項插入
struct NativeAdView: View {
    var body: some View {
        HStack(spacing: 12) {
            // 廣告圖示
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.gray.opacity(0.1))
                    .frame(width: 50, height: 50)
                
                Image(systemName: "megaphone.fill")
                    .foregroundColor(.secondary)
            }
            
            // 廣告內容
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("贊助內容")
                        .font(.body)
                        .fontWeight(.medium)
                    
                    Text("Ad")
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.yellow.opacity(0.3))
                        .clipShape(Capsule())
                }
                
                if SecretsManager.shared.isTestMode {
                    Text("測試模式 - 原生廣告區域")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else {
                    Text("廣告載入中...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    VStack {
        NativeAdView()
            .padding()
        
        Spacer()
        
        BannerAdView()
    }
    .environmentObject(UserManager.shared)
}
