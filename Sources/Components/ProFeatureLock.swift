import SwiftUI

/// Pro 功能鎖頭圖示
/// 顯示在需要訂閱才能使用的功能旁邊
struct ProFeatureLock: View {
    @EnvironmentObject var userManager: UserManager
    
    var body: some View {
        if userManager.isProUser {
            // Pro 用戶：顯示金色勾勾
            Image(systemName: "checkmark.seal.fill")
                .foregroundColor(.yellow)
                .font(.caption)
        } else {
            // 免費用戶：顯示鎖頭
            Image(systemName: "lock.fill")
                .foregroundColor(.secondary)
                .font(.caption)
        }
    }
}

/// Pro 功能按鈕修飾器
/// 自動為 Pro 功能添加鎖頭並處理點擊事件
struct ProFeatureModifier: ViewModifier {
    @EnvironmentObject var userManager: UserManager
    @Binding var showPaywall: Bool
    let action: () -> Void
    
    func body(content: Content) -> some View {
        Button {
            if userManager.isProUser {
                action()
            } else {
                showPaywall = true
            }
        } label: {
            HStack(spacing: 4) {
                content
                ProFeatureLock()
                    .environmentObject(userManager)
            }
        }
    }
}

extension View {
    /// 將視圖包裝為 Pro 功能按鈕
    func proFeature(showPaywall: Binding<Bool>, action: @escaping () -> Void) -> some View {
        modifier(ProFeatureModifier(showPaywall: showPaywall, action: action))
    }
}

#Preview {
    VStack(spacing: 20) {
        HStack {
            Text("優先推薦")
            ProFeatureLock()
        }
        
        HStack {
            Text("避雷模式")
            ProFeatureLock()
        }
    }
    .environmentObject(UserManager.shared)
}
