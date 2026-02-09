import SwiftUI

/// 熱量圖鑑頁面
struct EncyclopediaView: View {
    @StateObject private var viewModel = EncyclopediaViewModel()
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var userManager: UserManager
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.backgroundPrimary
                    .ignoresSafeArea()
                
                if viewModel.isLoading {
                    ProgressView("載入中...")
                } else {
                    drinkList
                }
            }
            .navigationTitle("找熱量")
            .navigationBarTitleDisplayMode(.large)
            .searchable(
                text: $viewModel.searchText,
                prompt: "搜尋飲料或品牌..."
            )
            .onChange(of: viewModel.searchText) { _, _ in
                viewModel.filterDrinks()
            }
            .sheet(isPresented: $viewModel.showAddLogModal) {
                if let drink = viewModel.selectedDrinkForLog {
                    AddToLogModal(
                        drink: drink,
                        onDismiss: { viewModel.dismissAddLogModal() },
                        onSave: { _, _, _, _ in
                            // 由 DiaryViewModel 處理儲存
                            viewModel.dismissAddLogModal()
                            // 跳轉到日記頁
                            appState.selectedTab = .diary
                        }
                    )
                    .environmentObject(appState)
                    .environmentObject(userManager)
                    .presentationDetents([.medium])
                }
            }
            .task {
                if viewModel.drinks.isEmpty {
                    await viewModel.loadData()
                }
            }
        }
    }
    
    private var drinkList: some View {
        ScrollViewReader { proxy in
            List {
                ForEach(Array(viewModel.drinksGroupedByBrand.enumerated()), id: \.element.brand.id) { index, group in
                    // 每個品牌之間插入一則 Native 廣告
                    if index > 0 {
                        NativeAdCardView()
                            .listRowBackground(Color.clear)
                    }
                    
                    Section {
                        ForEach(Array(group.drinks.enumerated()), id: \.element.id) { drinkIndex, drink in
                            // 每 10 個品項插入一則 Native 廣告
                            if drinkIndex > 0 && drinkIndex % 10 == 0 {
                                NativeAdCardView()
                                    .listRowBackground(Color.clear)
                            }
                            
                            DrinkListRow(
                                drink: drink,
                                onAddToLog: { viewModel.prepareAddLog(for: drink) }
                            )
                        }
                    } header: {
                        brandHeader(group.brand)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .onChange(of: appState.scrollToTopTrigger) { _, newValue in
                if newValue == .encyclopedia {
                    // 滾動到第一個品牌
                    if let firstBrand = viewModel.drinksGroupedByBrand.first {
                        withAnimation {
                            proxy.scrollTo(firstBrand.brand.id, anchor: .top)
                        }
                    }
                    appState.scrollToTopTrigger = nil
                }
            }
        }
    }


    
    private func brandHeader(_ brand: Brand) -> some View {
        HStack(spacing: 8) {
            // Logo placeholder
            Circle()
                .fill(Color.teaBrown.opacity(0.2))
                .frame(width: 24, height: 24)
                .overlay {
                    Text(String(brand.name.prefix(1)))
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.teaBrown)
                }
            
            Text(brand.name)
                .font(.headline)
                .foregroundColor(.teaBrown)
        }
        .padding(.vertical, 4)
    }
}

/// 飲料列表行
struct DrinkListRow: View {
    let drink: Drink
    let onAddToLog: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // 飲料圖示
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.milkCream)
                    .frame(width: 50, height: 50)
                
                Image(systemName: categoryIcon)
                    .font(.title3)
                    .foregroundColor(.teaBrown)
            }
            
            // 資訊
            VStack(alignment: .leading, spacing: 4) {
                Text(drink.name)
                    .font(.body)
                    .fontWeight(.medium)
                
                // 熱量與糖量
                HStack(spacing: 6) {
                    CalorieIndicator(calories: drink.baseCalories, style: .badge)
                    
                    if let sugar = drink.sugarGrams, sugar > 0 {
                        Text("\(Int(sugar))g糖")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(Color.gray.opacity(0.1))
                            .clipShape(Capsule())
                    }
                }
                
                // 咖啡因
                if drink.hasCaffeine {
                    HStack(spacing: 4) {
                        CaffeineIcon(hasCaffeine: true, showLabel: true)
                        if let mg = drink.caffeineContent, mg > 0 {
                            Text("(\(mg)mg)")
                                .font(.caption2)
                                .foregroundColor(.brown.opacity(0.8))
                        }
                    }
                }
            }
            
            Spacer()
            
            // 加入日記按鈕
            Button(action: onAddToLog) {
                Image(systemName: "plus.circle.fill")
                    .font(.title2)
                    .foregroundColor(.teaBrown)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 4)
    }
    
    private var categoryIcon: String {
        switch drink.category {
        case .milkTea: return "cup.and.saucer.fill"
        case .pureTea: return "leaf.fill"
        case .fruitTea: return "drop.fill"
        case .coffee: return "mug.fill"
        case .fresh: return "drop.fill"
        case .special: return "sparkles"
        }
    }
}

#Preview {
    EncyclopediaView()
        .environmentObject(AppState())
}
