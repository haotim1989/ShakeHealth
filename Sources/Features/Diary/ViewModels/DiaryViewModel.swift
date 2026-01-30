import SwiftUI
import SwiftData

/// 飲料日記 ViewModel
@MainActor
final class DiaryViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var logs: [DrinkLog] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showDeleteConfirmation = false
    @Published var logToDelete: DrinkLog?
    
    // 編輯模式
    @Published var isEditing = false
    @Published var editingLog: DrinkLog?
    
    // MARK: - Dependencies
    private let diaryService: DiaryServiceProtocol
    private var modelContext: ModelContext?
    
    // MARK: - Initialization
    init(diaryService: DiaryServiceProtocol = DiaryService.shared) {
        self.diaryService = diaryService
    }
    
    // MARK: - Setup
    func setup(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // MARK: - Actions
    
    /// 載入日記
    func loadLogs(userId: String) {
        guard let context = modelContext else { return }
        isLoading = true
        
        do {
            logs = try diaryService.fetchLogs(for: userId, context: context)
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    /// 新增日記
    func addLog(
        drink: Drink,
        userId: String,
        selectedSugar: SugarLevel,
        selectedIce: IceLevel,
        rating: Int,
        comment: String
    ) throws {
        guard let context = modelContext else { return }
        
        let log = DrinkLog(
            drinkId: drink.id,
            brandId: drink.brandId,
            userId: userId,
            selectedSugar: selectedSugar,
            selectedIce: selectedIce,
            rating: rating,
            comment: comment,
            drinkName: drink.name,
            brandName: drink.brand?.name ?? "",
            caloriesSnapshot: drink.calories(for: selectedSugar)
        )
        
        try diaryService.addLog(log, context: context)
        loadLogs(userId: userId)
        HapticManager.shared.success()
    }
    
    /// 更新日記
    func updateLog(
        _ log: DrinkLog,
        rating: Int,
        comment: String,
        selectedSugar: SugarLevel,
        selectedIce: IceLevel
    ) throws {
        guard let context = modelContext else { return }
        
        log.rating = rating
        log.comment = comment
        log.selectedSugar = selectedSugar
        log.selectedIce = selectedIce
        
        try diaryService.updateLog(log, context: context)
        HapticManager.shared.success()
    }
    
    /// 準備刪除日記
    func prepareDelete(_ log: DrinkLog) {
        logToDelete = log
        showDeleteConfirmation = true
    }
    
    /// 確認刪除日記
    func confirmDelete(userId: String) {
        guard let context = modelContext, let log = logToDelete else { return }
        
        do {
            try diaryService.deleteLog(log, context: context)
            loadLogs(userId: userId)
            HapticManager.shared.success()
        } catch {
            errorMessage = error.localizedDescription
            HapticManager.shared.error()
        }
        
        logToDelete = nil
        showDeleteConfirmation = false
    }
    
    /// 開始編輯
    func startEditing(_ log: DrinkLog) {
        editingLog = log
        isEditing = true
    }
    
    /// 取消編輯
    func cancelEditing() {
        editingLog = nil
        isEditing = false
    }
    
    // MARK: - Statistics
    
    /// 本週飲料數量
    var thisWeekCount: Int {
        let calendar = Calendar.current
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        return logs.filter { $0.createdAt >= weekAgo }.count
    }
    
    /// 本週總熱量
    var thisWeekCalories: Int {
        let calendar = Calendar.current
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        return logs
            .filter { $0.createdAt >= weekAgo }
            .reduce(0) { $0 + $1.caloriesSnapshot }
    }
    
    /// 平均評分
    var averageRating: Double {
        guard !logs.isEmpty else { return 0 }
        let total = logs.reduce(0) { $0 + $1.rating }
        return Double(total) / Double(logs.count)
    }
}
