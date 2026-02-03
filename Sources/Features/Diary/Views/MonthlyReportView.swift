import SwiftUI
import SwiftData

/// 月報表視圖 (Pro 功能)
struct MonthlyReportView: View {
    @EnvironmentObject var userManager: UserManager
    @Environment(\.dismiss) private var dismiss
    
    let logs: [DrinkLog]
    
    // 月份選擇
    @State private var selectedMonthOffset: Int = 0  // 0 = 當月, -1 = 上個月, etc.
    
    /// 計算有資料的月份 (用於限制切換範圍)
    private var monthsWithData: Set<Int> {
        var months = Set<Int>()
        let calendar = Calendar.current
        let now = Date()
        
        for log in logs {
            let monthDiff = calendar.dateComponents([.month], from: log.createdAt, to: now).month ?? 0
            if monthDiff >= 0 && monthDiff <= 11 {
                months.insert(-monthDiff)
            }
        }
        return months
    }
    
    private var hasMultipleMonthsWithData: Bool {
        monthsWithData.count > 1
    }
    
    private var selectedDate: Date {
        Calendar.current.date(byAdding: .month, value: selectedMonthOffset, to: Date()) ?? Date()
    }
    
    // 計算屬性
    private var displayMonth: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy 年 M 月"
        return formatter.string(from: selectedDate)
    }
    
    private var monthlyLogs: [DrinkLog] {
        let calendar = Calendar.current
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: selectedDate))!
        var endComponents = calendar.dateComponents([.year, .month], from: selectedDate)
        endComponents.month! += 1
        let endOfMonth = calendar.date(from: endComponents)!
        
        return logs.filter { $0.createdAt >= startOfMonth && $0.createdAt < endOfMonth }
    }
    
    private var totalCalories: Int {
        monthlyLogs.reduce(0) { $0 + $1.caloriesSnapshot }
    }
    
    private var totalDrinks: Int {
        monthlyLogs.count
    }
    
    private var averageRating: Double {
        guard !monthlyLogs.isEmpty else { return 0 }
        let sum = monthlyLogs.reduce(0) { $0 + $1.rating }
        return Double(sum) / Double(monthlyLogs.count)
    }
    
    private var topBrands: [(brand: String, count: Int)] {
        var brandCounts: [String: Int] = [:]
        for log in monthlyLogs {
            brandCounts[log.brandName, default: 0] += 1
        }
        return brandCounts.sorted { $0.value > $1.value }.prefix(3).map { ($0.key, $0.value) }
    }
    
    // 計算該月份的天數
    private var daysInMonth: Int {
        let calendar = Calendar.current
        if selectedMonthOffset == 0 {
            // 當月：使用今天的日期
            return calendar.component(.day, from: Date())
        } else {
            // 過去月份：使用該月的總天數
            let range = calendar.range(of: .day, in: .month, for: selectedDate)!
            return range.count
        }
    }
    
    // 健康紅綠燈 (根據衛福部建議: 每日糖分 < 50g，每月約 1500g)
    private var healthStatus: HealthStatus {
        // 假設每杯含糖飲料約 40g 糖 (中糖標準)
        let estimatedSugar = monthlyLogs.count * 40
        
        if estimatedSugar < 600 { // 每週少於 4 杯
            return .green
        } else if estimatedSugar < 1200 { // 每週 4-8 杯
            return .yellow
        } else {
            return .red
        }
    }
    
    enum HealthStatus {
        case green, yellow, red
        
        var color: Color {
            switch self {
            case .green: return .green
            case .yellow: return .yellow
            case .red: return .red
            }
        }
        
        var message: String {
            switch self {
            case .green: return "太棒了！這個月飲料攝取量適中 🎉"
            case .yellow: return "注意！建議適度控制含糖飲料 ⚠️"
            case .red: return "警告！本月飲料攝取量較高，請注意健康 🚨"
            }
        }
        
        var icon: String {
            switch self {
            case .green: return "checkmark.circle.fill"
            case .yellow: return "exclamationmark.triangle.fill"
            case .red: return "xmark.octagon.fill"
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // 月份選擇器
                    monthSelector
                    
                    // 健康紅綠燈
                    healthStatusCard
                    
                    // 統計卡片
                    statisticsSection
                    
                    // 最愛品牌
                    if !topBrands.isEmpty {
                        topBrandsSection
                    }
                    
                    // 無資料提示
                    if monthlyLogs.isEmpty {
                        noDataView
                    }
                }
                .padding()
            }
            .background(Color.backgroundPrimary)
            .navigationTitle("月報表")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    // MARK: - Month Selector
    
    private var monthSelector: some View {
        HStack {
            // 前一個有資料的月份
            if hasMultipleMonthsWithData, let prevMonth = previousMonthWithData {
                Button {
                    withAnimation {
                        selectedMonthOffset = prevMonth
                    }
                } label: {
                    Image(systemName: "chevron.left.circle.fill")
                        .font(.title2)
                        .foregroundColor(.teaBrown)
                }
            } else {
                // 佔位
                Image(systemName: "chevron.left.circle.fill")
                    .font(.title2)
                    .foregroundColor(.clear)
            }
            
            Spacer()
            
            Text(displayMonth)
                .font(.title2)
                .fontWeight(.bold)
            
            Spacer()
            
            // 後一個有資料的月份
            if hasMultipleMonthsWithData, let nextMonth = nextMonthWithData {
                Button {
                    withAnimation {
                        selectedMonthOffset = nextMonth
                    }
                } label: {
                    Image(systemName: "chevron.right.circle.fill")
                        .font(.title2)
                        .foregroundColor(.teaBrown)
                }
            } else {
                // 佔位
                Image(systemName: "chevron.right.circle.fill")
                    .font(.title2)
                    .foregroundColor(.clear)
            }
        }
        .padding()
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private var previousMonthWithData: Int? {
        let sorted = monthsWithData.sorted(by: >)  // 從大到小排序
        return sorted.first { $0 < selectedMonthOffset }
    }
    
    private var nextMonthWithData: Int? {
        let sorted = monthsWithData.sorted()  // 從小到大排序
        return sorted.first { $0 > selectedMonthOffset }
    }
    
    private var noDataView: some View {
        VStack(spacing: 12) {
            Image(systemName: "tray")
                .font(.system(size: 40))
                .foregroundColor(.secondary)
            Text("這個月還沒有紀錄")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(40)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    // MARK: - Health Status Card
    
    private var healthStatusCard: some View {
        VStack(spacing: 16) {
            Image(systemName: healthStatus.icon)
                .font(.system(size: 50))
                .foregroundColor(healthStatus.color)
            
            Text(healthStatus.message)
                .font(.headline)
                .multilineTextAlignment(.center)
            
            // 紅綠燈指示器
            HStack(spacing: 12) {
                trafficLight(.green, isActive: healthStatus == .green)
                trafficLight(.yellow, isActive: healthStatus == .yellow)
                trafficLight(.red, isActive: healthStatus == .red)
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 5, y: 2)
    }
    
    private func trafficLight(_ color: Color, isActive: Bool) -> some View {
        Circle()
            .fill(isActive ? color : color.opacity(0.2))
            .frame(width: 24, height: 24)
            .overlay(
                Circle()
                    .stroke(color.opacity(0.5), lineWidth: 2)
            )
    }
    
    // MARK: - Statistics Section
    
    private var statisticsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(displayMonth + " 統計")
                .font(.headline)
            
            HStack(spacing: 16) {
                statCard(title: "總杯數", value: "\(totalDrinks)", unit: "杯", icon: "cup.and.saucer.fill", color: .teaBrown)
                statCard(title: "總熱量", value: "\(totalCalories)", unit: "kcal", icon: "flame.fill", color: .orange)
            }
            
            HStack(spacing: 16) {
                statCard(title: "平均評分", value: String(format: "%.1f", averageRating), unit: "星", icon: "star.fill", color: .yellow)
                statCard(title: "日均杯數", value: String(format: "%.1f", daysInMonth > 0 ? Double(totalDrinks) / Double(daysInMonth) : 0), unit: "杯", icon: "calendar", color: .blue)
            }
        }
    }
    
    private func statCard(title: String, value: String, unit: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            HStack(alignment: .bottom, spacing: 4) {
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                Text(unit)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    // MARK: - Top Brands Section
    
    private var topBrandsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("最愛品牌 Top 3")
                .font(.headline)
            
            ForEach(Array(topBrands.enumerated()), id: \.offset) { index, item in
                HStack {
                    // 排名
                    Text("\(index + 1)")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .frame(width: 30, height: 30)
                        .background(rankColor(index))
                        .clipShape(Circle())
                    
                    Text(item.brand)
                        .font(.body)
                    
                    Spacer()
                    
                    Text("\(item.count) 杯")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    // 長條圖
                    GeometryReader { geo in
                        RoundedRectangle(cornerRadius: 4)
                            .fill(rankColor(index))
                            .frame(width: geo.size.width * CGFloat(item.count) / CGFloat(topBrands.first?.count ?? 1))
                    }
                    .frame(width: 80, height: 12)
                }
                .padding(.vertical, 8)
            }
        }
        .padding()
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    private func rankColor(_ index: Int) -> Color {
        switch index {
        case 0: return .yellow
        case 1: return .gray
        case 2: return .orange
        default: return .teaBrown
        }
    }
}

#Preview {
    MonthlyReportView(logs: [])
        .environmentObject(UserManager.shared)
}
