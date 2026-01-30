import SwiftUI

/// 熱量圖鑑頁面
struct EncyclopediaView: View {
    @StateObject private var viewModel = EncyclopediaViewModel()
    @EnvironmentObject var appState: AppState
    
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
        List {
            ForEach(viewModel.drinksGroupedByBrand, id: \.brand.id) { group in
                Section {
                    ForEach(group.drinks) { drink in
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
                
                HStack(spacing: 8) {
                    CalorieIndicator(calories: drink.baseCalories, style: .badge)
                    
                    if drink.hasCaffeine {
                        CaffeineIcon(hasCaffeine: true)
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
