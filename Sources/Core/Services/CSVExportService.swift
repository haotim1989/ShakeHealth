import Foundation
import SwiftData
import UniformTypeIdentifiers

/// CSV 匯出匯入服務
@MainActor
final class CSVExportService {
    static let shared = CSVExportService()
    
    private init() {}
    
    // MARK: - Export
    
    /// 將日記紀錄匯出為 CSV 字串
    func exportToCSV(logs: [DrinkLog]) -> String {
        var csv = "id,日期,飲料名稱,品牌,甜度,冰塊,熱量,含咖啡因,評分,感想\n"
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"
        
        for log in logs.sorted(by: { $0.createdAt > $1.createdAt }) {
            let row = [
                log.id,
                dateFormatter.string(from: log.createdAt),
                escapeCSV(log.drinkName),
                escapeCSV(log.brandName),
                log.selectedSugar.rawValue,
                log.selectedIce.rawValue,
                String(log.caloriesSnapshot),
                log.hasCaffeineSnapshot ? "是" : "否",
                String(log.rating),
                escapeCSV(log.comment)
            ].joined(separator: ",")
            csv += row + "\n"
        }
        
        return csv
    }
    
    /// 取得 CSV 檔案 URL (存到暫存目錄)
    func getExportFileURL(logs: [DrinkLog]) -> URL? {
        let csv = exportToCSV(logs: logs)
        let fileName = "飲料日記_\(formattedDate()).csv"
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        
        do {
            try csv.write(to: tempURL, atomically: true, encoding: .utf8)
            return tempURL
        } catch {
            print("❌ CSV 匯出失敗: \(error)")
            return nil
        }
    }
    
    // MARK: - Import
    
    /// 從 CSV 檔案匯入日記紀錄
    func importFromCSV(url: URL, userId: String, context: ModelContext) throws -> Int {
        let content = try String(contentsOf: url, encoding: .utf8)
        let lines = content.components(separatedBy: .newlines).filter { !$0.isEmpty }
        
        guard lines.count > 1 else { return 0 }
        
        var importCount = 0
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"
        
        for line in lines.dropFirst() {
            let columns = parseCSVLine(line)
            guard columns.count >= 10 else { continue }
            
            let logId = columns[0]
            let dateStr = columns[1]
            let drinkName = columns[2]
            let brandName = columns[3]
            let sugarRaw = columns[4]
            let iceRaw = columns[5]
            let calories = Int(columns[6]) ?? 0
            let hasCaffeine = columns[7] == "是"
            let rating = Int(columns[8]) ?? 3
            let comment = columns[9]
            
            let createdAt = dateFormatter.date(from: dateStr) ?? Date()
            let sugar = SugarLevel(rawValue: sugarRaw) ?? .sugar100
            let ice = IceLevel(rawValue: iceRaw) ?? .normalIce
            
            // 檢查是否已存在
            let descriptor = FetchDescriptor<DrinkLog>(predicate: #Predicate { $0.id == logId })
            if (try? context.fetch(descriptor).first) != nil {
                continue
            }
            
            let log = DrinkLog(
                id: logId,
                drinkId: "imported_\(logId)",
                brandId: "imported_brand",
                userId: userId,
                selectedSugar: sugar,
                selectedIce: ice,
                rating: rating,
                comment: comment,
                drinkName: drinkName,
                brandName: brandName,
                caloriesSnapshot: calories,
                hasCaffeineSnapshot: hasCaffeine,
                createdAt: createdAt
            )
            
            context.insert(log)
            importCount += 1
        }
        
        try context.save()
        return importCount
    }
    
    // MARK: - Helpers
    
    private func escapeCSV(_ text: String) -> String {
        if text.contains(",") || text.contains("\"") || text.contains("\n") {
            return "\"\(text.replacingOccurrences(of: "\"", with: "\"\""))\""
        }
        return text
    }
    
    private func parseCSVLine(_ line: String) -> [String] {
        var result: [String] = []
        var current = ""
        var inQuotes = false
        
        for char in line {
            if char == "\"" {
                inQuotes.toggle()
            } else if char == "," && !inQuotes {
                result.append(current)
                current = ""
            } else {
                current.append(char)
            }
        }
        result.append(current)
        
        return result
    }
    
    private func formattedDate() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd"
        return formatter.string(from: Date())
    }
}

/// CSV 檔案類型
struct CSVFile: FileDocument {
    static var readableContentTypes: [UTType] { [.commaSeparatedText] }
    
    var content: String
    
    init(content: String = "") {
        self.content = content
    }
    
    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents,
              let string = String(data: data, encoding: .utf8)
        else {
            throw CocoaError(.fileReadCorruptFile)
        }
        content = string
    }
    
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let data = content.data(using: .utf8)!
        return FileWrapper(regularFileWithContents: data)
    }
}
