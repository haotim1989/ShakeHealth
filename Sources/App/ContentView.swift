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
                        Image(systemName: "book.fill")
                            .renderingMode(.template)
                        Text("我的日記")
                    }
                    .tag(AppState.Tab.diary)
                    
                    VStack(spacing: 0) {
                        RandomPickerView()
                        BannerAdView()
                    }
                    .tabItem {
                        Image(systemName: "dice.fill")
                            .renderingMode(.template)
                        Text("隨機喝")
                    }
                    .tag(AppState.Tab.randomPicker)
                    
                    VStack(spacing: 0) {
                        EncyclopediaView()
                            .padding(.bottom, 0) // 確保緊貼底部
                        BannerAdView()
                    }
                    .tabItem {
                        Image(systemName: "magnifyingglass")
                            .renderingMode(.template)
                        Text("找熱量")
                    }
                    .tag(AppState.Tab.encyclopedia)
                    
                    VStack(spacing: 0) {
                        SettingsView()
                        BannerAdView()
                    }
                    .tabItem {
                        Image(systemName: "gearshape.fill")
                            .renderingMode(.template)
                        Text("設定")
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
