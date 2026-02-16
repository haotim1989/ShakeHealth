import SwiftUI
import SwiftData

/// 隨機推薦 ViewModel
@MainActor
final class RandomPickerViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var criteria = FilterCriteria()
    @Published var pickedDrink: Drink?
    @Published var allDrinks: [Drink] = []
    @Published var allBrands: [Brand] = []
    @Published var isLoading = false
    @Published var isShaking = false
    @Published var showNoResultAlert = false
    @Published var showFilterSheet = false
    @Published var errorMessage: String?
    @Published var showInsufficientDataHint = false  // 資料不足提示
    
    // MARK: - Dependencies
    private let pickerService: RandomPickerServiceProtocol
    private let drinkService: DrinkServiceProtocol
    private let hapticManager = HapticManager.shared
    let interstitialAdManager = InterstitialAdManager()
    
    // 用戶日記記錄 (由外部注入)
    var userLogs: [DrinkLog] = []
    
    // Pro 用戶狀態 (由外部設定)
    var isProUser: Bool = false
    
    // MARK: - Computed Properties
    var filteredCount: Int {
        allDrinks.filter { criteria.matches($0) }.count
    }
    
    var hasActiveFilters: Bool {
        !criteria.isEmpty
    }
    
    // MARK: - Initialization
    init(
        pickerService: RandomPickerServiceProtocol = RandomPickerService.shared,
        drinkService: DrinkServiceProtocol = DrinkService.shared
    ) {
        self.pickerService = pickerService
        self.drinkService = drinkService
    }
    
    // MARK: - Actions
    
    /// 載入初始資料
    func loadData() async {
        isLoading = true
        do {
            allDrinks = try await drinkService.fetchAllDrinks()
            allBrands = try await drinkService.fetchAllBrands()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
    
    /// 隨機抽取飲料
    func pickRandom() async {
        isShaking = true
        hapticManager.playShake()
        
        // 檢查智慧推薦資料是否足夠
        if criteria.smartPriority {
            let service = pickerService as? RandomPickerService
            if service?.hasInsufficientData(logs: userLogs) == true {
                showInsufficientDataHint = true
            }
        }
        
        // 動畫延遲
        try? await Task.sleep(nanoseconds: UInt64(Constants.Animation.shakeAnimation * 1_000_000_000))
        
        do {
            let drinks = try await pickerService.getFilteredDrinks(criteria: criteria, userLogs: userLogs)
            
            if let drink = drinks.randomElement() {
                // 更新每日抽獎計數
                let pickCount = incrementDailyPickCount()
                
                // 檢查是否需要展示插頁廣告 (非 Pro 用戶，每日第 N 次)
                let shouldShowAd = !isProUser
                    && Constants.FeatureFlags.interstitialAdsEnabled
                    && pickCount >= Constants.FeatureFlags.interstitialPickThreshold
                
                if shouldShowAd {
                    // 展示廣告，廣告結束後才顯示飲料
                    isShaking = false
                    await withCheckedContinuation { continuation in
                        interstitialAdManager.showAd {
                            continuation.resume()
                        }
                    }
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                        pickedDrink = drink
                    }
                    hapticManager.success()
                } else {
                    // 直接顯示飲料
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                        pickedDrink = drink
                    }
                    hapticManager.success()
                    isShaking = false
                }
            } else {
                showNoResultAlert = true
                hapticManager.error()
                isShaking = false
            }
        } catch {
            errorMessage = error.localizedDescription
            hapticManager.error()
            isShaking = false
        }
    }
    
    /// 再抽一次
    func pickAgain() async {
        pickedDrink = nil
        await pickRandom()
    }
    
    /// 開啟 Google Maps 尋找店家
    func openInMaps() {
        guard let drink = pickedDrink, let brand = drink.brand else { return }
        MapService.searchNearby(brand: brand.name)
    }
    
    /// 重置篩選條件
    func resetFilters() {
        criteria.reset()
        hapticManager.light()
    }
    
    /// 切換品牌篩選
    func toggleBrand(_ brandId: String) {
        if criteria.selectedBrands.contains(brandId) {
            criteria.selectedBrands.remove(brandId)
        } else {
            criteria.selectedBrands.insert(brandId)
        }
        hapticManager.selection()
    }
    
    /// 切換分類篩選
    func toggleCategory(_ category: DrinkCategory) {
        if criteria.selectedCategories.contains(category) {
            criteria.selectedCategories.remove(category)
        } else {
            criteria.selectedCategories.insert(category)
        }
        hapticManager.selection()
    }
    
    /// 設定甜度
    func setSugarLevel(_ level: SugarLevel?) {
        criteria.selectedSugarLevel = level
        hapticManager.selection()
    }
    
    /// 設定熱量區間
    func setCalorieRange(_ range: CalorieRange?) {
        criteria.calorieRange = range
        hapticManager.selection()
    }
    
    /// 設定咖啡因篩選
    func setCaffeineFilter(_ hasCaffeine: Bool?) {
        criteria.hasCaffeine = hasCaffeine
        hapticManager.selection()
    }
    
    // MARK: - Pro Features
    
    /// 設定智慧推薦 (Pro)
    func setSmartPriority(_ enabled: Bool) {
        criteria.smartPriority = enabled
        hapticManager.selection()
    }
    
    /// 設定避雷模式 (Pro)
    func setAntiThunder(_ enabled: Bool) {
        criteria.antiThunder = enabled
        hapticManager.selection()
    }
    
    // MARK: - Private Helpers
    
    /// 增加每日抽獎計數並回傳更新後的次數
    private func incrementDailyPickCount() -> Int {
        let defaults = UserDefaults.standard
        let today = Calendar.current.startOfDay(for: Date())
        
        // 檢查是否同一天
        if let savedDate = defaults.object(forKey: Constants.StorageKeys.dailyPickDate) as? Date,
           Calendar.current.isDate(savedDate, inSameDayAs: today) {
            // 同一天，累加計數
            let count = defaults.integer(forKey: Constants.StorageKeys.dailyPickCount) + 1
            defaults.set(count, forKey: Constants.StorageKeys.dailyPickCount)
            return count
        } else {
            // 新的一天，重置計數
            defaults.set(today, forKey: Constants.StorageKeys.dailyPickDate)
            defaults.set(1, forKey: Constants.StorageKeys.dailyPickCount)
            return 1
        }
    }
}
