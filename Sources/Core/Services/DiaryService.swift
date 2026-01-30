import Foundation
import SwiftData

/// 日記服務協議
protocol DiaryServiceProtocol {
    func addLog(_ log: DrinkLog, context: ModelContext) throws
    func fetchLogs(for userId: String, context: ModelContext) throws -> [DrinkLog]
    func updateLog(_ log: DrinkLog, context: ModelContext) throws
    func deleteLog(_ log: DrinkLog, context: ModelContext) throws
}

/// 日記服務實作 (使用 SwiftData 本地儲存)
final class DiaryService: DiaryServiceProtocol {
    static let shared = DiaryService()
    
    private init() {}
    
    /// 新增日記
    func addLog(_ log: DrinkLog, context: ModelContext) throws {
        // 驗證評論字數
        guard DrinkLog.validateComment(log.comment) else {
            throw DiaryServiceError.commentTooLong
        }
        
        // 驗證評分
        guard DrinkLog.validateRating(log.rating) else {
            throw DiaryServiceError.invalidRating
        }
        
        context.insert(log)
        try context.save()
    }
    
    /// 取得用戶所有日記 (依時間倒序)
    func fetchLogs(for userId: String, context: ModelContext) throws -> [DrinkLog] {
        let descriptor = FetchDescriptor<DrinkLog>(
            predicate: #Predicate { $0.userId == userId },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return try context.fetch(descriptor)
    }
    
    /// 更新日記
    func updateLog(_ log: DrinkLog, context: ModelContext) throws {
        guard DrinkLog.validateComment(log.comment) else {
            throw DiaryServiceError.commentTooLong
        }
        
        guard DrinkLog.validateRating(log.rating) else {
            throw DiaryServiceError.invalidRating
        }
        
        log.updatedAt = Date()
        try context.save()
    }
    
    /// 刪除日記
    func deleteLog(_ log: DrinkLog, context: ModelContext) throws {
        context.delete(log)
        try context.save()
    }
}

// MARK: - Errors
enum DiaryServiceError: LocalizedError {
    case commentTooLong
    case invalidRating
    case saveFailed
    case notFound
    
    var errorDescription: String? {
        switch self {
        case .commentTooLong: return "評論不可超過 20 字"
        case .invalidRating: return "評分必須在 1-5 之間"
        case .saveFailed: return "儲存失敗"
        case .notFound: return "找不到該筆日記"
        }
    }
}
