import SwiftUI
import SwiftData
#if canImport(FirebaseCore)
import FirebaseCore
#endif
#if canImport(FirebaseCrashlytics)
import FirebaseCrashlytics
#endif

@main
struct ShakeHealthApp: App {
    @StateObject private var appState = AppState()
    @StateObject private var userManager = UserManager.shared
    
    // 建立 ModelContainer (處理 schema 遷移與 iCloud 同步)
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([DrinkLog.self])
        
        // 透過 UserManager 檢查是否為 Pro，因為 ModelContainer 會在初始階段被建立
        // (若為更進階的動態切換，需要在登入後動態重建 Container，這邊以啟動時狀態為準)
        let isProUser = UserManager.shared.isProUser
        
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: isProUser ? .automatic : .none
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
        setupSDKs()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .environmentObject(userManager)
                .task {
                    // Crashlytics 用戶綁定 (必須在 View 掛載後才能存取 StateObject)
                    #if canImport(FirebaseCrashlytics)
                    Crashlytics.crashlytics().setUserID(appState.userId)
                    Crashlytics.crashlytics().setCustomValue(userManager.isProUser, forKey: "isProUser")
                    #endif
                    
                    // 延遲請求 ATT 追蹤授權 (避免啟動時立即彈窗)
                    try? await Task.sleep(nanoseconds: 2_000_000_000)
                    await AdManager.shared.requestTrackingAuthorization()
                }
        }
        .modelContainer(sharedModelContainer)
    }
    
    private func setupSDKs() {
        #if canImport(FirebaseCore)
        // 注意：若無 GoogleService-Info.plist 會閃退，這裡做個防呆
        if Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist") != nil {
            FirebaseApp.configure()
            
            print("🔥 Firebase 已初始化")
        } else {
            print("⚠️ 未找到 GoogleService-Info.plist，Firebase 略過初始化")
        }
        #endif
        
        // 1. RevenueCat 訂閱服務
        SubscriptionService.shared.configure()
        
        // 2. AdMob 廣告服務
        AdManager.shared.configure()
        
        print("📱 ShakeHealth 啟動 (測試模式: \(SecretsManager.shared.isTestMode))")
    }
    
    private func setupAppearance() {
        // 設定 Tab Bar 外觀
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithOpaqueBackground()
        tabBarAppearance.backgroundColor = UIColor(Color.backgroundPrimary)
        
        // 修正 iOS 18+ 未選取標籤全黑的問題 (徹底決解方案)
        let itemAppearance = UITabBarItemAppearance()
        itemAppearance.normal.iconColor = .systemGray
        itemAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor.systemGray]
        
        tabBarAppearance.stackedLayoutAppearance = itemAppearance
        tabBarAppearance.inlineLayoutAppearance = itemAppearance
        tabBarAppearance.compactInlineLayoutAppearance = itemAppearance
        
        UITabBar.appearance().standardAppearance = tabBarAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
        
        // 保險起見追加 UIKit 的傳統全域設定
        UITabBar.appearance().unselectedItemTintColor = .systemGray
        UITabBar.appearance().tintColor = UIColor(Color.teaBrown)
        
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
    @Published var selectedTab: Tab = .diary
    @Published var userId: String = UUID().uuidString // 匿名用戶 ID
    @Published var scrollToTopTrigger: Tab? = nil  // 觸發置頂的 Tab
    
    // 控制啟動載入畫面的狀態
    @Published var isDataLoaded: Bool = false
    
    enum Tab: Hashable {
        case randomPicker
        case encyclopedia
        case diary
        case settings
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
