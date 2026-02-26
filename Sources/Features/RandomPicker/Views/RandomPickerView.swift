import SwiftUI
import SwiftData

/// 隨機推薦頁面
struct RandomPickerView: View {
    @StateObject private var viewModel = RandomPickerViewModel()
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var userManager: UserManager
    @Query private var allLogs: [DrinkLog]
    
    @State private var showInfoAlert = false
    
    /// 當前用戶的日記記錄
    private var userLogs: [DrinkLog] {
        allLogs.filter { $0.userId == appState.userId }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // 背景
                Color.backgroundPrimary
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // 自訂標題 (固定在頂部，避免被轉場動畫遮擋)
                    customHeader
                        .zIndex(100)
                    
                    GeometryReader { geometry in
                        ScrollView {
                            VStack(spacing: 0) {
                            
                            // 篩選條件區 (只在未抽到結果時顯示)
                            if viewModel.pickedDrink == nil {
                                filterSection
                                    .transition(.move(edge: .top).combined(with: .opacity))
                            }
                            
                            Spacer()
                            
                            // 主要內容區
                            if let drink = viewModel.pickedDrink {
                                // 結果卡片
                                DrinkResultCard(
                                    drink: drink,
                                    criteria: viewModel.criteria,
                                    onFindStore: {
                                        AnalyticsService.shared.logEvent(.randomPickerResultAction, parameters: [AnalyticsService.ParamKey.action: "find_store"])
                                        viewModel.openInMaps()
                                    },
                                    onPickAgain: {
                                        AnalyticsService.shared.logEvent(.randomPickerResultAction, parameters: [AnalyticsService.ParamKey.action: "pick_again"])
                                        Task { await viewModel.pickAgain() }
                                    },
                                    onShowFilter: {
                                        viewModel.showFilterSheet = true
                                    }
                                )
                                .padding(.horizontal, 24)
                                .transition(.asymmetric(
                                    insertion: .scale.combined(with: .opacity),
                                    removal: .opacity
                                ))
                            } else if viewModel.isShaking {
                                // 搖動動畫
                                ShakeAnimationView(isShaking: $viewModel.isShaking)
                                    .transition(.opacity)
                            } else {
                                // 初始狀態
                                initialStateView
                                    .transition(.opacity)
                            }
                            
                            Spacer()
                            
                            // 底部按鈕
                            if viewModel.pickedDrink == nil && !viewModel.isShaking {
                                ShakeButton(isLoading: viewModel.isLoading) {
                                    AnalyticsService.shared.logEvent(.randomPickerRoll, parameters: [AnalyticsService.ParamKey.triggerType: "button"])
                                    Task { await viewModel.pickRandom() }
                                }
                                .padding(.horizontal, 24)
                                .padding(.bottom, 24)
                            }
                        }
                        .frame(minHeight: geometry.size.height)
                    }
                }
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $viewModel.showFilterSheet) {
                FilterSheet(viewModel: viewModel)
                    .presentationDetents([.medium, .large])
            }
            .alert("找不到符合條件的飲料", isPresented: $viewModel.showNoResultAlert) {
                Button("調整篩選") {
                    viewModel.showFilterSheet = true
                }
                Button("清除篩選") {
                    viewModel.resetFilters()
                }
            } message: {
                Text("請放寬篩選條件，或清除所有篩選重新開始。")
            }
            .alert("智慧推薦提示", isPresented: $viewModel.showInsufficientDataHint) {
                Button("我知道了", role: .cancel) { }
            } message: {
                Text("累積更多評分後，推薦會更準確喔！\n目前紀錄較少，將使用普通隨機模式。")
            }
            .alert("關於隨機喝", isPresented: $showInfoAlert) {
                Button("了解", role: .cancel) { }
            } message: {
                Text("我們會根據您的篩選條件，從圖鑑中隨機挑選一杯飲料。\n若您有特定偏好（如：不要咖啡因、熱量限制），請先設定篩選條件。")
            }
            .task {
                if viewModel.allDrinks.isEmpty {
                    await viewModel.loadData()
                }
            }
            .onChange(of: userLogs) { _, newLogs in
                viewModel.userLogs = newLogs
            }
            .onAppear {
                AnalyticsService.shared.logEvent(.randomPickerView)
                viewModel.userLogs = userLogs
                viewModel.isProUser = userManager.isProUser
            }
            .onChange(of: userManager.isProUser) { _, newValue in
                viewModel.isProUser = newValue
            }

        }
    }
    
    // MARK: - Subviews
    
    private var customHeader: some View {
        HStack(spacing: 8) {
            Text("隨機喝")
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
    }
    
    private var filterSection: some View {
        Button {
            viewModel.showFilterSheet = true
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "slider.horizontal.3")
                    .font(.title3)
                
                Text(viewModel.hasActiveFilters ? "篩選條件 (\(viewModel.criteria.activeFilterCount))" : "設定篩選條件")
                    .font(.headline)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(viewModel.hasActiveFilters ? Color.teaBrown : Color.white)
            .foregroundColor(viewModel.hasActiveFilters ? .white : .teaBrown)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.teaBrown, lineWidth: viewModel.hasActiveFilters ? 0 : 2)
            )
            .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
        }
        .padding(.horizontal, 24)
        .padding(.top, 8)
        .padding(.bottom, 8)
    }
    
    private var activeFiltersBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: "line.3.horizontal.decrease.circle.fill")
            Text("\(viewModel.criteria.activeFilterCount)")
        }
        .font(.subheadline)
        .fontWeight(.semibold)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.teaBrown)
        .foregroundColor(.white)
        .clipShape(Capsule())
        .onTapGesture {
            viewModel.showFilterSheet = true
        }
    }
    
    private var filterButton: some View {
        Button {
            viewModel.showFilterSheet = true
        } label: {
            Image(systemName: "slider.horizontal.3")
                .font(.title3)
                .foregroundColor(.teaBrown)
                .overlay(alignment: .topTrailing) {
                    if viewModel.hasActiveFilters {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 8, height: 8)
                            .offset(x: 4, y: -4)
                    }
                }
        }
    }
    
    private var initialStateView: some View {
        VStack(spacing: 24) {
            // 扭蛋機風格 — 分類圖示動態展示
            GashaponIconsView()
            
            VStack(spacing: 8) {
                Text("今天喝什麼？")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.teaBrown)
                
                Text("選擇你的偏好條件，讓我來幫你決定！")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            // 統計資訊

        }
        .padding()
    }
}

// MARK: - 扭蛋機動態圖示

/// 扭蛋機風格的分類圖示動畫
struct GashaponIconsView: View {
    /// 六個飲品分類（排除 .custom）
    private let categories: [DrinkCategory] = DrinkCategory.allCases.filter { $0 != .custom }
    
    @State private var isAnimating = false
    @State private var orbitAngle: Double = 0
    @State private var pulseScale: CGFloat = 1.0
    
    // 中央圓的大小
    private let centerSize: CGFloat = 60
    // 軌道半徑
    private let orbitRadius: CGFloat = 110
    // 圖示大小
    private let iconSize: CGFloat = 80
    
    var body: some View {
        ZStack {
            // 中央底座
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color.milkCream, Color.milkCream.opacity(0.5)],
                        center: .center,
                        startRadius: 0,
                        endRadius: centerSize / 2
                    )
                )
                .frame(width: centerSize, height: centerSize)
                .shadow(color: .teaBrown.opacity(0.1), radius: 12, y: 4)
                .scaleEffect(pulseScale)
            
            // 中央問號
            Text("?")
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .foregroundColor(.teaBrown.opacity(0.6))
                .scaleEffect(pulseScale)
            
            // 6 個分類圖示繞軌道排列
            ForEach(Array(categories.enumerated()), id: \.element.id) { index, category in
                let baseAngle = Double(index) * (360.0 / Double(categories.count))
                let currentAngle = baseAngle + orbitAngle
                let radian = currentAngle * .pi / 180
                
                let x = orbitRadius * CGFloat(cos(radian))
                let y = orbitRadius * CGFloat(sin(radian))
                
                ZStack {
                    Circle()
                        .fill(category.themeColor.opacity(0.15))
                        .frame(width: iconSize, height: iconSize)
                    
                    CategoryIconView(category: category, size: iconSize * 0.6)
                }
                .offset(x: x, y: y)
            }
        }
        .frame(width: (orbitRadius + iconSize / 2) * 2, height: (orbitRadius + iconSize / 2) * 2)
        .onAppear {
            // 緩慢持續旋轉
            withAnimation(
                .linear(duration: 12)
                .repeatForever(autoreverses: false)
            ) {
                orbitAngle = 360
            }
            
            // 中央脈衝
            withAnimation(
                .easeInOut(duration: 2.0)
                .repeatForever(autoreverses: true)
            ) {
                pulseScale = 1.08
            }
            
            isAnimating = true
        }
    }
}

#Preview {
    RandomPickerView()
        .environmentObject(AppState())
}
