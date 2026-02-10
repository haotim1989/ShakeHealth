import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var userManager: UserManager
    
    var body: some View {
        TabView(selection: tabBinding) {
            VStack(spacing: 0) {
                RandomPickerView()
                BannerAdView()
            }
            .tabItem {
                Label("隨機喝", systemImage: "dice.fill")
            }
            .tag(AppState.Tab.randomPicker)
            
            VStack(spacing: 0) {
                EncyclopediaView()
                    .padding(.bottom, 0) // 確保緊貼底部
                BannerAdView()
            }
            .tabItem {
                Label("找熱量", systemImage: "magnifyingglass")
            }
            .tag(AppState.Tab.encyclopedia)
            
            VStack(spacing: 0) {
                DiaryView()
                BannerAdView()
            }
            .tabItem {
                Label("我的日記", systemImage: "book.fill")
            }
            .tag(AppState.Tab.diary)
            
            VStack(spacing: 0) {
                SettingsView()
                BannerAdView()
            }
            .tabItem {
                Label("設定", systemImage: "gearshape.fill")
            }
            .tag(AppState.Tab.settings)
        }
        .tint(.teaBrown)
        .preferredColorScheme(.light)
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
