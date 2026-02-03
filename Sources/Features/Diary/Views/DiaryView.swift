import SwiftUI
import SwiftData

/// 飲料日記頁面
struct DiaryView: View {
    @StateObject private var viewModel = DiaryViewModel()
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var userManager: UserManager
    @Environment(\.modelContext) private var modelContext
    
    @Query(sort: \DrinkLog.createdAt, order: .reverse)
    private var logs: [DrinkLog]
    
    @State private var showMonthlyReport = false
    @State private var showPaywall = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.backgroundPrimary
                    .ignoresSafeArea()
                
                if logs.isEmpty {
                    emptyStateView
                } else {
                    diaryList
                }
            }
            .navigationTitle("我的日記")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    reportButton
                }
                ToolbarItem(placement: .topBarTrailing) {
                    addButton
                }
            }
            .alert("確認刪除", isPresented: $viewModel.showDeleteConfirmation) {
                Button("取消", role: .cancel) {}
                Button("刪除", role: .destructive) {
                    viewModel.confirmDelete(userId: appState.userId)
                }
            } message: {
                Text("確定要刪除這筆日記嗎？此操作無法復原。")
            }
            .sheet(isPresented: $showMonthlyReport) {
                MonthlyReportView(logs: logs)
                    .environmentObject(userManager)
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView()
                    .environmentObject(userManager)
            }
        }
    }
    
    // MARK: - Subviews
    
    private var reportButton: some View {
        Button {
            if userManager.isProUser {
                showMonthlyReport = true
            } else {
                showPaywall = true
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "doc.text.magnifyingglass")
                    .font(.title3)
                    .fontWeight(.medium)
                Text("月報表")
                    .font(.subheadline)
                    .fontWeight(.medium)
                if !userManager.isProUser {
                    Image(systemName: "lock.fill")
                        .font(.caption)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.teaBrown.opacity(0.1))
            .foregroundColor(.teaBrown)
            .clipShape(Capsule())
        }
    }
    
    private var addButton: some View {
        Button {
            appState.selectedTab = .encyclopedia
        } label: {
            Image(systemName: "plus.circle.fill")
                .font(.title2)
                .foregroundColor(.teaBrown)
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(Color.milkCream)
                    .frame(width: 120, height: 120)
                
                Image(systemName: "book.closed")
                    .font(.system(size: 50))
                    .foregroundColor(.teaBrown.opacity(0.6))
            }
            
            VStack(spacing: 8) {
                Text("還沒有任何紀錄")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text("開始記錄你喝過的飲料吧！")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Button {
                appState.selectedTab = .encyclopedia
            } label: {
                HStack {
                    Image(systemName: "plus")
                    Text("加入第一筆")
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 14)
                .background(Color.teaBrown)
                .clipShape(Capsule())
            }
        }
        .padding()
    }
    
    private var diaryList: some View {
        List {
            // 統計區
            statisticsSection
            
            // 日記列表
            Section {
                ForEach(logs) { log in
                    NavigationLink(destination: DiaryDetailView(log: log)) {
                        DiaryEntryRow(log: log)
                    }
                }
                .onDelete(perform: deleteLogs)
            } header: {
                Text("紀錄列表")
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
    }
    
    private var statisticsSection: some View {
        Section {
            HStack(spacing: 16) {
                statisticCard(
                    title: "本週飲料",
                    value: "\(thisWeekCount)",
                    icon: "cup.and.saucer.fill",
                    color: .teaBrown
                )
                
                statisticCard(
                    title: "本週熱量",
                    value: "\(thisWeekCalories)",
                    unit: "kcal",
                    icon: "flame.fill",
                    color: Color.forCalories(thisWeekCalories / max(thisWeekCount, 1))
                )
            }
            .listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets())
            .padding(.vertical, 8)
        }
    }
    
    private func statisticCard(
        title: String,
        value: String,
        unit: String? = nil,
        icon: String,
        color: Color
    ) -> some View {
        VStack(spacing: 8) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(color)
                
                if let unit = unit {
                    Text(unit)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.03), radius: 5, y: 2)
    }
    
    // MARK: - Computed Properties
    
    private var thisWeekCount: Int {
        let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        return logs.filter { $0.createdAt >= weekAgo }.count
    }
    
    private var thisWeekCalories: Int {
        let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        return logs
            .filter { $0.createdAt >= weekAgo }
            .reduce(0) { $0 + $1.caloriesSnapshot }
    }
    
    // MARK: - Actions
    
    private func deleteLogs(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(logs[index])
        }
    }
}

/// 日記列表行
struct DiaryEntryRow: View {
    let log: DrinkLog
    
    var body: some View {
        HStack(spacing: 12) {
            // 日期
            VStack(spacing: 2) {
                Text(log.createdAt.formatted(.dateTime.day()))
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.teaBrown)
                Text(log.createdAt.formatted(.dateTime.month(.abbreviated)))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(width: 44)
            
            Divider()
                .frame(height: 40)
            
            // 飲料資訊
            VStack(alignment: .leading, spacing: 4) {
                Text(log.drinkName)
                    .font(.body)
                    .fontWeight(.medium)
                
                Text(log.brandName)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // 評分
            StarRatingDisplay(rating: log.rating, starSize: 12)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    DiaryView()
        .environmentObject(AppState())
        .modelContainer(for: DrinkLog.self, inMemory: true)
}
