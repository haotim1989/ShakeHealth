import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var userManager: UserManager
    
    @State private var showPaywall = false
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            TabView(selection: $appState.selectedTab) {
                RandomPickerView()
                    .tabItem {
                        Label("隨機喝", systemImage: "dice.fill")
                    }
                    .tag(AppState.Tab.randomPicker)
                
                EncyclopediaView()
                    .tabItem {
                        Label("找熱量", systemImage: "magnifyingglass")
                    }
                    .tag(AppState.Tab.encyclopedia)
                
                DiaryView()
                    .tabItem {
                        Label("我的日記", systemImage: "book.fill")
                    }
                    .tag(AppState.Tab.diary)
            }
            .tint(.teaBrown)
            
            // Pro Crown Button (固定右上角)
            proCrownButton
                .padding(.top, 50)
                .padding(.trailing, 16)
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView()
                .environmentObject(userManager)
        }
    }
    
    private var proCrownButton: some View {
        Group {
            // 只有非 Premium 用戶才顯示皇冠按鈕
            if !userManager.isProUser {
                Button {
                    showPaywall = true
                } label: {
                    VStack(spacing: 2) {
                        Image(systemName: "crown.fill")
                            .font(.title3)
                        Text("Premium")
                            .font(.system(size: 9))
                            .fontWeight(.bold)
                    }
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color(red: 1.0, green: 0.84, blue: 0.0), Color(red: 0.85, green: 0.65, blue: 0.13)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .shadow(color: .black.opacity(0.3), radius: 1, y: 1)
                }
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AppState())
        .environmentObject(UserManager.shared)
}
