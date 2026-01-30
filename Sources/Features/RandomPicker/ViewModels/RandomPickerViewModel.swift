import SwiftUI

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
    
    // MARK: - Dependencies
    private let pickerService: RandomPickerServiceProtocol
    private let drinkService: DrinkServiceProtocol
    private let hapticManager = HapticManager.shared
    
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
        
        // 動畫延遲
        try? await Task.sleep(nanoseconds: UInt64(Constants.Animation.shakeAnimation * 1_000_000_000))
        
        do {
            let drinks = try await pickerService.getFilteredDrinks(criteria: criteria)
            
            if let drink = drinks.randomElement() {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                    pickedDrink = drink
                }
                hapticManager.success()
            } else {
                showNoResultAlert = true
                hapticManager.error()
            }
        } catch {
            errorMessage = error.localizedDescription
            hapticManager.error()
        }
        
        isShaking = false
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
    
    /// 切換甜度篩選
    func toggleSugarLevel(_ level: SugarLevel) {
        if criteria.selectedSugarLevels.contains(level) {
            criteria.selectedSugarLevels.remove(level)
        } else {
            criteria.selectedSugarLevels.insert(level)
        }
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
}
