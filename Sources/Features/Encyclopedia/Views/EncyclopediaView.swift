import SwiftUI

/// 熱量圖鑑頁面
struct EncyclopediaView: View {
    @StateObject private var viewModel = EncyclopediaViewModel()
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var userManager: UserManager
    
    @State private var showPaywall = false
    
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
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    premiumCrownButton
                }
            }
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
            .sheet(isPresented: $showPaywall) {
                PaywallView()
                    .environmentObject(userManager)
            }
            .task {
                if viewModel.drinks.isEmpty {
                    await viewModel.loadData()
                }
            }
        }
    }
    
    // MARK: - Premium Crown
    
    private var premiumCrownButton: some View {
        Group {
            if !userManager.isProUser {
                Button {
                    showPaywall = true
                } label: {
                    VStack(spacing: 2) {
                        Image(systemName: "crown.fill")
                            .font(.body)
                        Text("Premium")
                            .font(.system(size: 8))
                            .fontWeight(.bold)
                    }
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color(red: 1.0, green: 0.84, blue: 0.0), Color(red: 0.85, green: 0.65, blue: 0.13)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
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
