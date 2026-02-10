import SwiftUI
import SwiftData

/// 隨機推薦頁面
struct RandomPickerView: View {
    @StateObject private var viewModel = RandomPickerViewModel()
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var userManager: UserManager
    @Query private var allLogs: [DrinkLog]
    
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
                    // 篩選條件區
                    filterSection
                    
                    Spacer()
                    
                    // 主要內容區
                    if let drink = viewModel.pickedDrink {
                        // 結果卡片
                        DrinkResultCard(
                            drink: drink,
                            criteria: viewModel.criteria,
                            onFindStore: { viewModel.openInMaps() },
                            onPickAgain: {
                                Task { await viewModel.pickAgain() }
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
                            Task { await viewModel.pickRandom() }
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 24)
                    }
                }
            }
            .navigationTitle("隨機喝")
            .navigationBarTitleDisplayMode(.large)
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
            .task {
                if viewModel.allDrinks.isEmpty {
                    await viewModel.loadData()
                }
            }
            .onChange(of: userLogs) { _, newLogs in
                viewModel.userLogs = newLogs
            }
            .onAppear {
                viewModel.userLogs = userLogs
            }
        }
    }
    
    // MARK: - Subviews
    
    private var filterSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                // 篩選按鈕 (移到最左邊)
                Button {
                    viewModel.showFilterSheet = true
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "slider.horizontal.3")
                        Text("篩選")
                        if viewModel.hasActiveFilters {
                            Text("(\(viewModel.criteria.activeFilterCount))")
                        }
                    }
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(viewModel.hasActiveFilters ? Color.teaBrown : Color.teaBrown.opacity(0.2))
                    .foregroundColor(viewModel.hasActiveFilters ? .white : .teaBrown)
                    .clipShape(Capsule())
                }
                
                // 快速篩選 chips
                ForEach(DrinkCategory.allCases) { category in
                    FilterChip(
                        title: category.rawValue,
                        isSelected: viewModel.criteria.selectedCategories.contains(category)
                    ) {
                        viewModel.toggleCategory(category)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .background(Color.white.opacity(0.8))
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
            // 搖搖杯圖示
            ZStack {
                Circle()
                    .fill(Color.milkCream)
                    .frame(width: 160, height: 160)
                
                Image(systemName: "cup.and.saucer.fill")
                    .font(.system(size: 70))
                    .foregroundColor(.teaBrown)
            }
            
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

#Preview {
    RandomPickerView()
        .environmentObject(AppState())
}
