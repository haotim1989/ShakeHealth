import SwiftUI
import SwiftData

/// 月報表視圖 (Pro 功能)
struct MonthlyReportView: View {
    @EnvironmentObject var userManager: UserManager
    @Environment(\.dismiss) private var dismiss
    
    let logs: [DrinkLog]
    
    // 月份選擇
    @State private var selectedMonthOffset: Int = 0  // 0 = 當月, -1 = 上個月, etc.
    @State private var showHealthInfo = false  // 顯示衛福部建議提示
    @State private var showCaffeineInfo = false // 顯示咖啡因建議提示
    
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
    
    // 健康紅綠燈 (根據衛福部建議: 每日糖分 < 50g)
    // 判定標準（依日均糖量）：
    // 🟢 適中：日均 < 40g
    // 🟡 注意：日均 40g ~ 60g
    // 🔴 警告：日均 > 60g
    private var healthStatus: HealthStatus {
        let dailyAverage = daysInMonth > 0 ? calculateTotalSugar() / Double(daysInMonth) : 0
        
        if dailyAverage < 40 {
            return .green
        } else if dailyAverage <= 60 {
            return .yellow
        } else {
            return .red
        }
    }
    
    private func calculateTotalSugar() -> Double {
        var totalSugar: Double = 0
        
        for log in monthlyLogs {
            // 優先使用快照資料 (自訂飲料或是有修改過數據的紀錄)
            if let sugarSnapshot = log.sugarSnapshot {
                totalSugar += sugarSnapshot
            } else if let drink = DrinkService.shared.getDrink(byId: log.drinkId), let baseSugar = drink.sugarGrams {
                // 若為圖鑑內的飲料且有基礎糖量，根據甜度比例計算
                totalSugar += baseSugar * log.selectedSugar.sugarPercentage
            }
            // 若為自訂飲料且未填寫糖分，或是圖鑑飲料無糖分數據，皆視為 0 不做推測估算
        }
        
        return totalSugar
    }
    
    // MARK: - Caffeine Calculation
    
    private func calculateTotalCaffeine() -> Double {
        var totalCaffeine: Double = 0
        
        for log in monthlyLogs {
            // 優先使用快照資料
            if let caffeineSnapshot = log.caffeineSnapshot {
                totalCaffeine += Double(caffeineSnapshot)
            } else if let drink = DrinkService.shared.getDrink(byId: log.drinkId) {
                // 嘗試從 Service 取得飲品原始資料
                // 如果有咖啡因含量數據
                if let content = drink.caffeineContent, content >= 0 {
                    totalCaffeine += Double(content)
                } else if let hasCaffeine = drink.hasCaffeine, hasCaffeine {
                    // 若標示含咖啡因但無數據，使用預設估算值 (約一杯中杯拿鐵/奶茶)
                    totalCaffeine += 150.0
                }
            } else {
                // 若找不到飲品資料，依據快照判斷
                if log.hasCaffeineSnapshot {
                    totalCaffeine += 150.0
                }
            }
        }
        
        return totalCaffeine
    }
    
    // MARK: - Spending Calculation
    
    /// 計算月總花費
    private func calculateTotalSpending() -> Int {
        monthlyLogs.compactMap { $0.price }.reduce(0, +)
    }
    
    /// 計算每日花費明細
    private func dailySpending() -> [(date: String, amount: Int)] {
        let formatter = DateFormatter()
        formatter.dateFormat = "M/d"
        
        var dayMap: [String: Int] = [:]
        var dayOrder: [String] = []
        
        for log in monthlyLogs {
            guard let price = log.price, price > 0 else { continue }
            let key = formatter.string(from: log.createdAt)
            if dayMap[key] == nil {
                dayOrder.append(key)
            }
            dayMap[key, default: 0] += price
        }
        
        return dayOrder.map { (date: $0, amount: dayMap[$0]!) }
    }
    
    // MARK: - Health Status Enum (Sugar)
    enum HealthStatus {
        case green, yellow, red
        
        var color: Color {
            switch self {
            case .green: return .green
            case .yellow: return .caloriesMedium // 修改為橘色 (參考咖啡因)
            case .red: return .red
            }
        }
        
        var message: String {
            switch self {
            case .green: return "日均糖分攝取適中 🎉"
            case .yellow: return "日均糖分已超過 40g ⚠️"
            case .red: return "日均糖分超過 60g 🚨"
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

    // 咖啡因紅綠燈 (參考歐盟建議: 成人每日 < 300-400mg)
    // 🟢 適量：日均 < 200mg
    // 🟡 注意：日均 200mg ~ 300mg
    // 🔴 過量：日均 > 300mg
    private var caffeineHealthStatus: CaffeineHealthStatus {
        let dailyAverage = daysInMonth > 0 ? calculateTotalCaffeine() / Double(daysInMonth) : 0
        
        if dailyAverage < 200 {
            return .green
        } else if dailyAverage <= 300 {
            return .yellow
        } else {
            return .red
        }
    }
    
    enum CaffeineHealthStatus {
        case green, yellow, red
        
        var color: Color {
            switch self {
            case .green: return .green // 修改為綠色 (參考糖分)
            case .yellow: return .caloriesMedium
            case .red: return .caloriesHigh
            }
        }
        
        var message: String {
            switch self {
            case .green: return "咖啡因攝取適量 🎉"
            case .yellow: return "日均咖啡因稍高 ⚠️"
            case .red: return "日均咖啡因過量 🚨"
            }
        }
        
        var icon: String {
            switch self {
            case .green: return "checkmark.circle.fill" // 修改為打勾 (參考糖分)
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
                    
                    // 健康分析卡片 (糖分 & 咖啡因)
                    healthStatusCards
                    
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
                    
                    // 花費統計 (包含每日明細)
                    if calculateTotalSpending() > 0 {
                        spendingSection
                    }
                }
                .padding()
                .onAppear {
                    AnalyticsService.shared.logEvent(.monthlyReportView, parameters: [
                        AnalyticsService.ParamKey.totalSugar: Int(calculateTotalSugar())
                    ])
                }
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
    
    // ... (Month Selector logic remains same) ...
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
    
    // MARK: - Health Status Cards
    
    private var healthStatusCards: some View {
        HStack(spacing: 14) {
            // 糖分卡片
            healthCard(
                title: "日均糖量",
                value: String(format: "%.1f", daysInMonth > 0 ? calculateTotalSugar() / Double(daysInMonth) : 0),
                unit: "g",
                statusMessage: healthStatus.message,
                statusColor: healthStatus.color,
                icon: healthStatus.icon,
                action: { showHealthInfo = true }
            )
            
            // 咖啡因卡片
            healthCard(
                title: "日均咖啡因",
                value: String(format: "%.0f", daysInMonth > 0 ? calculateTotalCaffeine() / Double(daysInMonth) : 0),
                unit: "mg",
                statusMessage: caffeineHealthStatus.message,
                statusColor: caffeineHealthStatus.color,
                icon: caffeineHealthStatus.icon,
                action: { showCaffeineInfo = true }
            )
        }
        .alert("衛福部建議", isPresented: $showHealthInfo) {
            Button("我知道了", role: .cancel) { }
        } message: {
            Text("每日攝取糖量不超過 50g\n（約一杯全糖手搖飲料）")
        }
        .alert("歐盟食品安全局建議", isPresented: $showCaffeineInfo) {
            Button("我知道了", role: .cancel) { }
        } message: {
            Text("成人每日咖啡因攝取量不建議超過 300mg\n（約 2-3 杯咖啡或茶）\n過量可能導致心悸、失眠等症狀。")
        }
    }
    
    private func healthCard(title: String, value: String, unit: String, statusMessage: String, statusColor: Color, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top) {
                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundColor(statusColor)
                        .frame(width: 32, height: 32)
                        .background(statusColor.opacity(0.15))
                        .clipShape(Circle())
                    
                    Spacer()
                    
                    Text("詳細")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.secondary.opacity(0.1))
                        .clipShape(Capsule())
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    HStack(alignment: .firstTextBaseline, spacing: 2) {
                        Text(value)
                            .font(.system(.title2, design: .rounded))
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        Text(unit)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Text(statusMessage)
                    .font(.system(size: 11))
                    .foregroundColor(statusColor)
                    .lineLimit(1)
                    .padding(.top, 4)
            }
            .padding(16)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.03), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func trafficLight(_ color: Color, isActive: Bool) -> some View {
        Circle()
            .fill(isActive ? color : color.opacity(0.2))
            .frame(width: 8, height: 8)
    }
    
    // MARK: - Statistics Section
    
    private var statisticsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(displayMonth + " 統計")
                .font(.headline)
            
            // 重點數據：日均杯數
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("日均杯數")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    HStack(alignment: .firstTextBaseline) {
                        Text(String(format: "%.1f", daysInMonth > 0 ? Double(totalDrinks) / Double(daysInMonth) : 0))
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(.teaBrown)
                        
                        Text("杯 / 天")
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                }
                Spacer()
                Image(systemName: "checklist")
                    .font(.system(size: 40))
                    .foregroundColor(.teaBrown.opacity(0.2))
            }
            .padding()
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            
            HStack(spacing: 16) {
                statCard(title: "總杯數", value: "\(totalDrinks)", unit: "杯", icon: "cup.and.saucer.fill", color: .teaBrown)
                statCard(title: "總熱量", value: "\(totalCalories)", unit: "kcal", icon: "flame.fill", color: .orange)
            }
            
            HStack(spacing: 16) {
                statCard(title: "總糖量", value: String(format: "%.0f", calculateTotalSugar()), unit: "g", icon: "cube.fill", color: .pink)
                statCard(title: "總咖啡因", value: String(format: "%.0f", calculateTotalCaffeine()), unit: "mg", icon: "drop.fill", color: .coffeeBrown)
            }
            
            if calculateTotalSpending() > 0 {
                HStack(spacing: 16) {
                    statCard(title: "總花費", value: "\(calculateTotalSpending())", unit: "元", icon: "dollarsign.circle.fill", color: .green)
                    statCard(title: "日均花費", value: String(format: "%.0f", daysInMonth > 0 ? Double(calculateTotalSpending()) / Double(daysInMonth) : 0), unit: "元", icon: "calendar.badge.clock", color: .green)
                }
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
    
    // MARK: - Spending Section
    
    private var spendingSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "dollarsign.circle.fill")
                    .foregroundColor(.green)
                Text("花費明細")
                    .font(.headline)
            }
            
            let daily = dailySpending()
            
            ForEach(Array(daily.enumerated()), id: \.offset) { _, item in
                HStack {
                    Text(item.date)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .frame(width: 50, alignment: .leading)
                    
                    // 簡易長條圖
                    GeometryReader { geo in
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.green.opacity(0.6))
                            .frame(width: geo.size.width * CGFloat(item.amount) / CGFloat(daily.map(\.amount).max() ?? 1))
                    }
                    .frame(height: 12)
                    
                    Text("NT$ \(item.amount)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .frame(width: 80, alignment: .trailing)
                }
                .padding(.vertical, 4)
            }
        }
        .padding()
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

#Preview {
    MonthlyReportView(logs: [])
        .environmentObject(UserManager.shared)
}
