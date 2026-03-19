import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var userManager: UserManager
    
    @State private var showOnboarding = !UserDefaults.standard.bool(forKey: Constants.StorageKeys.onboardingCompleted)
    
    var body: some View {
        ZStack {
            if !appState.isDataLoaded {
                SplashLoadingView()
                    .transition(.opacity)
                    .task {
                        // 在背景非同步載入資料
                        await DrinkService.shared.loadDataAsync()
                        
                        // 確保至少顯示一下，避免畫面閃爍太快 (可選)
                        try? await Task.sleep(nanoseconds: 500_000_000)
                        
                        // 載入完成，切換到主畫面
                        await MainActor.run {
                            withAnimation(.easeOut(duration: 0.4)) {
                                appState.isDataLoaded = true
                            }
                        }
                    }
            } else {
                TabView(selection: tabBinding) {
                    VStack(spacing: 0) {
                        DiaryView()
                        BannerAdView()
                    }
                    .tabItem {
                        tabIcon(name: "book.fill", title: "我的日記", isSelected: appState.selectedTab == .diary)
                    }
                    .tag(AppState.Tab.diary)
                    
                    VStack(spacing: 0) {
                        RandomPickerView()
                        BannerAdView()
                    }
                    .tabItem {
                        tabIcon(name: "dice.fill", title: "隨機喝", isSelected: appState.selectedTab == .randomPicker)
                    }
                    .tag(AppState.Tab.randomPicker)
                    
                    VStack(spacing: 0) {
                        EncyclopediaView()
                            .padding(.bottom, 0) // 確保緊貼底部
                        BannerAdView()
                    }
                    .tabItem {
                        tabIcon(name: "magnifyingglass", title: "找熱量", isSelected: appState.selectedTab == .encyclopedia)
                    }
                    .tag(AppState.Tab.encyclopedia)
                    
                    VStack(spacing: 0) {
                        SettingsView()
                        BannerAdView()
                    }
                    .tabItem {
                        tabIcon(name: "gearshape.fill", title: "設定", isSelected: appState.selectedTab == .settings)
                    }
                    .tag(AppState.Tab.settings)
                }
                .tint(.teaBrown) // 恢復 tint 以確保按鈕與選取狀態正確
                .preferredColorScheme(.light)
                .transition(.opacity)
                .fullScreenCover(isPresented: $showOnboarding) {
                    OnboardingView(isPresented: $showOnboarding)
                }
            }
        }
    }
    
    /// 100% 自信解決方案：生成預先染色且為 .alwaysOriginal 的圖片
    /// 避免 iOS 18 Liquid Glass 渲染機制強制將圖示塗黑/變藍
    @ViewBuilder
    private func tabIcon(name: String, title: String, isSelected: Bool) -> some View {
        let color = isSelected ? UIColor(red: 139/255, green: 111/255, blue: 71/255, alpha: 1.0) : UIColor(red: 153/255, green: 153/255, blue: 153/255, alpha: 1.0)
        
        if let uiImage = UIImage(systemName: name)?.withTintColor(color, renderingMode: .alwaysOriginal) {
            Image(uiImage: uiImage)
            Text(title)
                .foregroundColor(Color(color)) // 保險起見文字也指定顏色
        } else {
            // Fallback (通常不會發生)
            Image(systemName: name)
            Text(title)
        }
    }
    
    /// 自訂 Tab Binding：偵測重複點擊觸發置頂
    private var tabBinding: Binding<AppState.Tab> {
        Binding(
            get: { appState.selectedTab },
            set: { newTab in
                if newTab == appState.selectedTab {
                    // 重複點擊當前 Tab：觸發置頂
                    appState.scrollToTopTrigger = newTab
                } else {
                    // 切換到不同 Tab
                    appState.selectedTab = newTab
                }
            }
        )
    }
}

#Preview {
    ContentView()
        .environmentObject(AppState())
        .environmentObject(UserManager.shared)
}

struct SplashLoadingView: View {
    var body: some View {
        ZStack {
            Color.backgroundPrimary
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                // 使用 App 的 LaunchIcon (或是可更換為其他圖片)
                Image("LaunchIcon")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120, height: 120)
                
                ProgressView()
                    .tint(.teaBrown)
                    .scaleEffect(1.5)
            }
        }
    }
}
