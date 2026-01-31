import SwiftUI
import SwiftData

@main
struct ShakeHealthApp: App {
    @StateObject private var appState = AppState()
    
    // 建立 ModelContainer (處理 schema 遷移)
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([DrinkLog.self])
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false
        )
        
        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            // 如果遷移失敗，嘗試刪除舊資料重建
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
    
    init() {
        setupAppearance()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
        }
        .modelContainer(sharedModelContainer)
    }
    
    private func setupAppearance() {
        // 設定 Tab Bar 外觀
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithOpaqueBackground()
        tabBarAppearance.backgroundColor = UIColor(Color.backgroundPrimary)
        UITabBar.appearance().standardAppearance = tabBarAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
        
        // 設定 Navigation Bar 外觀
        let navBarAppearance = UINavigationBarAppearance()
        navBarAppearance.configureWithOpaqueBackground()
        navBarAppearance.backgroundColor = UIColor(Color.backgroundPrimary)
        navBarAppearance.titleTextAttributes = [.foregroundColor: UIColor(Color.teaBrown)]
        navBarAppearance.largeTitleTextAttributes = [.foregroundColor: UIColor(Color.teaBrown)]
        UINavigationBar.appearance().standardAppearance = navBarAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navBarAppearance
    }
}

/// 全域應用程式狀態
@MainActor
final class AppState: ObservableObject {
    @Published var selectedTab: Tab = .randomPicker
    @Published var userId: String = UUID().uuidString // 匿名用戶 ID
    
    enum Tab: Hashable {
        case randomPicker
        case encyclopedia
        case diary
    }
    
    init() {
        // 從 UserDefaults 讀取匿名用戶 ID，若無則建立新的
        if let savedUserId = UserDefaults.standard.string(forKey: "anonymousUserId") {
            self.userId = savedUserId
        } else {
            let newUserId = UUID().uuidString
            UserDefaults.standard.set(newUserId, forKey: "anonymousUserId")
            self.userId = newUserId
        }
    }
}
