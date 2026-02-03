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
        Button {
            if userManager.isProUser {
                // 已是 Pro 用戶，可顯示訂閱資訊或不做任何動作
            } else {
                showPaywall = true
            }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "crown.fill")
                    .font(.subheadline)
                if userManager.isProUser {
                    Text("Pro")
                        .font(.caption)
                        .fontWeight(.bold)
                }
            }
            .padding(.horizontal, userManager.isProUser ? 12 : 10)
            .padding(.vertical, 8)
            .background(
                userManager.isProUser
                    ? Color.yellow.opacity(0.9)
                    : Color.yellow.opacity(0.8)
            )
            .foregroundColor(.black)
            .clipShape(Capsule())
            .shadow(color: .black.opacity(0.15), radius: 4, y: 2)
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AppState())
        .environmentObject(UserManager.shared)
}
