import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
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
    }
}

#Preview {
    ContentView()
        .environmentObject(AppState())
}
