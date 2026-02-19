import SwiftUI

/// 熱量圖鑑頁面
struct EncyclopediaView: View {
    @StateObject private var viewModel = EncyclopediaViewModel()
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var userManager: UserManager
    
    @State private var showInfoAlert = false

    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 自訂標題與搜尋列
                customHeader
                customSearchBar
                
                ZStack {
                    Color.backgroundPrimary
                        .ignoresSafeArea()
                    
                    if viewModel.isLoading {
                        ProgressView("載入中...")
                    } else {
                        drinkList
                    }
                }
            }
            .toolbar(.hidden, for: .navigationBar)
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
            .alert("關於找熱量", isPresented: $showInfoAlert) {
                Button("了解", role: .cancel) { }
            } message: {
                Text("本圖鑑之熱量與糖分數據僅供參考，實際數值可能因店家配方調整、冰塊甜度選擇而有差異。\n若有醫療需求，請諮詢專業醫師。")
            }
            .task {
                if viewModel.drinks.isEmpty {
                    await viewModel.loadData()
                }
            }
            .onTapGesture {
                hideKeyboard()
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
            .scrollDismissesKeyboard(.immediately)
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


    

    
    private var customHeader: some View {
        HStack(spacing: 8) {
            Text("找熱量")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.teaBrown)
            
            Button {
                showInfoAlert = true
            } label: {
                Image(systemName: "info.circle")
                    .font(.title2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.horizontal, 24)
        .padding(.top, 16)
        .padding(.bottom, 8)
        .background(Color.backgroundPrimary)
    }
    
    private var customSearchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField("搜尋飲料或品牌...", text: $viewModel.searchText)
                .textFieldStyle(.plain)
            
            if !viewModel.searchText.isEmpty {
                Button {
                    viewModel.searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(10)
        .background(Color.gray.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .padding(.horizontal, 24)
        .padding(.bottom, 12)
        .background(Color.backgroundPrimary)
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
    
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
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
                    .fill(drink.category.themeColor.opacity(0.12))
                    .frame(width: 50, height: 50)
                
                CategoryIconView(category: drink.category, size: 30)
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
                
                // 咖啡因資訊
                if let mg = drink.caffeineContent, mg == -1 {
                    // 1. 資料不足
                    HStack(spacing: 4) {
                        Image(systemName: "cup.and.saucer")
                            .font(.caption)
                        Text("咖啡因資料不足")
                            .font(.caption2)
                    }
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.gray.opacity(0.1))
                    .clipShape(Capsule())
                } else if let hasCaffeine = drink.hasCaffeine {
                    if hasCaffeine {
                        // 2. 含咖啡因
                        HStack(spacing: 4) {
                            CaffeineIcon(hasCaffeine: true, showLabel: true)
                            if let mg = drink.caffeineContent, mg > 0 {
                                Text("(\(mg)mg)")
                                    .font(.caption2)
                                    .foregroundColor(.brown.opacity(0.8))
                            }
                        }
                    } else {
                        // 3. 無咖啡因
                        CaffeineIcon(hasCaffeine: false, showLabel: true)
                    }
                } else {
                    // 4. hasCaffeine 為 nil (也是資料不足)
                    HStack(spacing: 4) {
                        Image(systemName: "cup.and.saucer")
                            .font(.caption)
                        Text("資料不足")
                            .font(.caption2)
                    }
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.gray.opacity(0.1))
                    .clipShape(Capsule())
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
}

#Preview {
    EncyclopediaView()
        .environmentObject(AppState())
}
