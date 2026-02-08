import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var userManager: UserManager
    
    var body: some View {
        TabView(selection: $appState.selectedTab) {
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
        }
        .tint(.teaBrown)
    }
}

#Preview {
    ContentView()
        .environmentObject(AppState())
        .environmentObject(UserManager.shared)
}
