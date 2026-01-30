import SwiftUI

/// 熱量圖鑑 ViewModel
@MainActor
final class EncyclopediaViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var drinks: [Drink] = []
    @Published var brands: [Brand] = []
    @Published var filteredDrinks: [Drink] = []
    @Published var criteria = FilterCriteria()
    @Published var searchText = ""
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // Add to Log Modal
    @Published var selectedDrinkForLog: Drink?
    @Published var showAddLogModal = false
    
    // MARK: - Dependencies
    private let drinkService: DrinkServiceProtocol
    
    // MARK: - Initialization
    init(drinkService: DrinkServiceProtocol = DrinkService.shared) {
        self.drinkService = drinkService
    }
    
    // MARK: - Computed Properties
    
    /// 依品牌分組的飲料
    var drinksGroupedByBrand: [(brand: Brand, drinks: [Drink])] {
        let grouped = Dictionary(grouping: filteredDrinks) { $0.brandId }
        return brands.compactMap { brand in
            guard let drinks = grouped[brand.id], !drinks.isEmpty else { return nil }
            return (brand: brand, drinks: drinks)
        }
    }
    
    // MARK: - Actions
    
    /// 載入資料
    func loadData() async {
        isLoading = true
        do {
            drinks = try await drinkService.fetchAllDrinks()
            brands = try await drinkService.fetchAllBrands()
            filterDrinks()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
    
    /// 篩選飲料
    func filterDrinks() {
        var result = drinks
        
        // 搜尋文字過濾
        if !searchText.isEmpty {
            let query = searchText.lowercased()
            result = result.filter { drink in
                drink.name.lowercased().contains(query) ||
                (drink.brand?.name.lowercased().contains(query) ?? false)
            }
        }
        
        // 條件過濾
        if !criteria.isEmpty {
            result = result.filter { criteria.matches($0) }
        }
        
        filteredDrinks = result
    }
    
    /// 準備新增日記
    func prepareAddLog(for drink: Drink) {
        selectedDrinkForLog = drink
        showAddLogModal = true
        HapticManager.shared.light()
    }
    
    /// 關閉新增日記 Modal
    func dismissAddLogModal() {
        showAddLogModal = false
        selectedDrinkForLog = nil
    }
    
    /// 重置搜尋與篩選
    func resetSearch() {
        searchText = ""
        criteria.reset()
        filterDrinks()
    }
}
