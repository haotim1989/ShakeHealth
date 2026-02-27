import SwiftUI
import SwiftData

/// 日記詳情頁面
struct DiaryDetailView: View {
    @Bindable var log: DrinkLog
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var isEditing = false
    @State private var editedDate: Date
    @State private var editedRating: Int
    @State private var editedComment: String
    @State private var editedSugar: SugarLevel
    @State private var editedIce: IceLevel
    
    // 自訂飲料編輯欄位
    @State private var editedName: String
    @State private var editedBrand: String
    @State private var editedCalories: String
    @State private var editedSugarSnapshot: String
    @State private var editedCaffeineSnapshot: String
    
    // 配料 & 風味評鑑
    @State private var editedToppings: Set<Topping>
    @State private var editedTasteTexture: String
    @State private var editedTasteTea: String
    @State private var editedTasteMilk: String
    @State private var editedTasteSweetness: String
    @State private var editedTasteIce: String
    @State private var editedTasteSmoothness: String
    @State private var editedTasteAroma: String
    
    // 消費體驗
    @State private var editedExpCostPerformance: String
    @State private var editedExpOccasion: String
    @State private var editedExpRepurchase: String
    @State private var editedExpPortion: String
    @State private var editedExpWaitTime: String
    
    @State private var showDeleteConfirmation = false
    
    init(log: DrinkLog) {
        self.log = log
        self._editedRating = State(initialValue: log.rating)
        self._editedComment = State(initialValue: log.comment)
        self._editedSugar = State(initialValue: log.selectedSugar)
        self._editedIce = State(initialValue: log.selectedIce)
        
        // 初始化自訂欄位
        self._editedName = State(initialValue: log.drinkName)
        self._editedBrand = State(initialValue: log.brandName)
        self._editedCalories = State(initialValue: String(log.caloriesSnapshot - log.toppingsCalories))
        self._editedSugarSnapshot = State(initialValue: log.sugarSnapshot.map { String(format: "%.0f", $0) } ?? "")
        self._editedCaffeineSnapshot = State(initialValue: log.caffeineSnapshot.map { String($0) } ?? "")
        
        // 配料 & 風味
        self._editedToppings = State(initialValue: log.selectedToppings)
        self._editedTasteTexture = State(initialValue: log.tasteTexture)
        self._editedTasteTea = State(initialValue: log.tasteTea)
        self._editedTasteMilk = State(initialValue: log.tasteMilk)
        self._editedTasteSweetness = State(initialValue: log.tasteSweetness)
        self._editedTasteIce = State(initialValue: log.tasteIce)
        self._editedTasteSmoothness = State(initialValue: log.tasteSmoothness)
        self._editedTasteAroma = State(initialValue: log.tasteAroma)
        self._editedExpCostPerformance = State(initialValue: log.expCostPerformance)
        self._editedExpOccasion = State(initialValue: log.expOccasion)
        self._editedExpRepurchase = State(initialValue: log.expRepurchase)
        self._editedExpPortion = State(initialValue: log.expPortion)
        self._editedExpWaitTime = State(initialValue: log.expWaitTime)
        
        self._editedDate = State(initialValue: log.createdAt)
    }
    
    private var isCustomDrink: Bool {
        log.drinkId.hasPrefix("custom_")
    }
    
    /// 表單驗證：評論不能超過 30 字
    private var isValidForm: Bool {
        let isCommentValid = editedComment.count <= 30
        
        if isCustomDrink {
            let isCaloriesValid = (Int(editedCalories) ?? 0) <= 9999
            let isSugarValid = (Double(editedSugarSnapshot) ?? 0) <= 9999
            let isCaffeineValid = (Int(editedCaffeineSnapshot) ?? 0) <= 9999
            return isCommentValid && isCaloriesValid && isSugarValid && isCaffeineValid
        }
        
        return isCommentValid
    }
    
    /// 目前顯示的熱量 (編輯模式下會即時計算，含配料熱量)
    private var currentDisplayCalories: Int {
        if isEditing {
            let baseCalories: Int
            if isCustomDrink {
                baseCalories = Int(editedCalories) ?? 0
            } else if let drink = DrinkService.shared.getDrink(byId: log.drinkId) {
                baseCalories = drink.calories(for: editedSugar)
            } else {
                baseCalories = log.caloriesSnapshot - log.toppingsCalories
            }
            return baseCalories + Topping.totalCalories(editedToppings)
        } else {
            return log.caloriesSnapshot
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // 日期選擇器 / 顯示
                if isEditing {
                    DatePicker(
                        "記錄時間",
                        selection: $editedDate,
                        in: ...Date(),
                        displayedComponents: [.date, .hourAndMinute]
                    )
                    .padding()
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                } else {
                    HStack {
                        Image(systemName: "calendar")
                            .foregroundColor(.teaBrown)
                        Text(formatDate(log.createdAt))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                    .padding(.horizontal)
                }
                
                // 飲料資訊卡片
                drinkInfoCard
                
                // 規格資訊
                specificationCard
                
                // 配料資訊
                toppingsCard
                
                // 風味評鑑
                tasteProfileCard
                
                // 消費體驗
                consumerExperienceCard
                
                // 評價資訊
                ratingCard
                
                // 刪除按鈕
                deleteButton
            }
            .padding(20)
        }
        .background(Color.backgroundPrimary)
        .navigationTitle("日記詳情")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(isEditing ? "完成" : "編輯") {
                    if isEditing {
                        saveChanges()
                    }
                    isEditing.toggle()
                }
                .fontWeight(.semibold)
                .disabled(isEditing && !isValidForm)
            }
        }
        .alert("確認刪除", isPresented: $showDeleteConfirmation) {
            Button("取消", role: .cancel) {}
            Button("刪除", role: .destructive) {
                deleteLog()
            }
        } message: {
            Text("確定要刪除這筆日記嗎？此操作無法復原。")
        }
        .scrollDismissesKeyboard(.immediately)
        .background(
            Color.backgroundPrimary
                .onTapGesture {
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                }
        )
    }
    
    // MARK: - Subviews
    
    private var drinkInfoCard: some View {
        VStack(spacing: 16) {
            // 飲料圖示
            ZStack {
                Circle()
                    .fill(log.category.themeColor.opacity(0.1))
                    .frame(width: 80, height: 80)
                
                CategoryIconView(category: log.category, size: 40)
            }
            
            VStack(spacing: 4) {
                if isEditing && isCustomDrink {
                    TextField("飲料名稱", text: $editedName)
                        .font(.title2)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                        .padding(8)
                        .background(Color.gray.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    
                    TextField("品牌名稱", text: $editedBrand)
                        .font(.subheadline)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                        .padding(8)
                        .background(Color.gray.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                } else {
                    Text(log.drinkName)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text(log.brandName)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            
            // 熱量與咖啡因/糖分 (自訂編輯模式下顯示詳細輸入)
            if isEditing && isCustomDrink {
                VStack(spacing: 12) {
                    Divider()
                    HStack(alignment: .top, spacing: 12) {
                        editNutritionInput(
                            title: "熱量 (kcal)",
                            text: $editedCalories,
                            keyboardType: .numberPad,
                            isValid: (Int(editedCalories) ?? 0) <= 9999
                        )
                        editNutritionInput(
                            title: "糖分 (g)",
                            text: $editedSugarSnapshot,
                            keyboardType: .decimalPad,
                            isValid: (Double(editedSugarSnapshot) ?? 0) <= 9999
                        )
                        editNutritionInput(
                            title: "咖啡因 (mg)",
                            text: $editedCaffeineSnapshot,
                            keyboardType: .numberPad,
                            isValid: (Int(editedCaffeineSnapshot) ?? 0) <= 9999
                        )
                    }
                }
            } else {
                HStack(spacing: 12) {
                    CalorieIndicator(calories: currentDisplayCalories, style: .detailed)
                    
                    if !isCustomDrink,
                       let drink = DrinkService.shared.getDrink(byId: log.drinkId),
                       drink.hasCaffeine == nil {
                        // 資料不足 (樣式沿用 EncyclopediaView)
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
                    } else if log.hasCaffeineSnapshot || isCustomDrink { 
                        let caffeine = log.caffeineSnapshot ?? (log.hasCaffeineSnapshot ? -1 : 0)
                        if caffeine > 0 || log.hasCaffeineSnapshot {
                            CaffeineIcon(hasCaffeine: true, showLabel: true)
                        } else {
                             // 顯示無咖啡因
                             CaffeineIcon(hasCaffeine: false, showLabel: true)
                        }
                    } else {
                        // 如果是圖鑑飲料且無咖啡因快照，也顯示無咖啡因
                         CaffeineIcon(hasCaffeine: false, showLabel: true)
                    }
                }
            }
            
            // 紀錄時間
            Text(log.createdAt.formatted(date: .abbreviated, time: .shortened))
                .font(.caption)
                .foregroundColor(.secondary)
            
            // 分享按鈕
            shareButton
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.05), radius: 10, y: 5)
    }
    
    private var shareButton: some View {
        Button {
            ShareService.share(log: log)
        } label: {
            HStack {
                Image(systemName: "square.and.arrow.up")
                Text("分享")
            }
            .font(.subheadline)
            .fontWeight(.medium)
            .foregroundColor(.teaBrown)
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(Color.teaBrown.opacity(0.1))
            .clipShape(Capsule())
        }
    }
    
    private var specificationCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("規格")
                .font(.headline)
            
            HStack {
                specItem(
                    title: "甜度",
                    value: isEditing ? editedSugar.rawValue : log.selectedSugar.rawValue,
                    icon: "drop.fill"
                )
                
                Spacer()
                
                specItem(
                    title: "冰塊",
                    value: isEditing ? editedIce.rawValue : log.selectedIce.rawValue,
                    icon: "snowflake"
                )
            }
            
            if isEditing {
                Divider()
                
                // 甜度選擇
                VStack(alignment: .leading, spacing: 8) {
                    Text("修改甜度")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(SugarLevel.allCases) { level in
                                editableSpecButton(
                                    title: level.shortName,
                                    isSelected: editedSugar == level
                                ) {
                                    editedSugar = level
                                }
                            }
                        }
                    }
                }
                
                // 冰塊選擇
                VStack(alignment: .leading, spacing: 8) {
                    Text("修改冰塊")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(IceLevel.allCases) { level in
                                editableSpecButton(
                                    title: level.rawValue,
                                    isSelected: editedIce == level
                                ) {
                                    editedIce = level
                                }
                            }
                        }
                    }
                }
            }
        }
        .padding(20)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    private func specItem(title: String, value: String, icon: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.teaBrown)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
        }
        .frame(maxWidth: .infinity)
    }
    
    private func editableSpecButton(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(isSelected ? Color.teaBrown : Color.gray.opacity(0.1))
                .foregroundColor(isSelected ? .white : .primary)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
    
    private var ratingCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("評價")
                .font(.headline)
            
            // 評分
            HStack {
                Text("評分")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                if isEditing {
                    StarRatingView(rating: $editedRating, starSize: 24)
                } else {
                    StarRatingDisplay(rating: log.rating, starSize: 20)
                }
            }
            
            Divider()
            
            // 評論
            VStack(alignment: .leading, spacing: 8) {
                Text("感想")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                if isEditing {
                    CharacterCountTextField(text: $editedComment)
                } else {
                    Text(log.comment.isEmpty ? "沒有留下感想" : log.comment)
                        .font(.body)
                        .foregroundColor(log.comment.isEmpty ? .secondary : .primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .padding(20)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    // MARK: - Toppings Card
    
    private var toppingsCard: some View {
        Group {
            if isEditing {
                ToppingsSection(selectedToppings: $editedToppings)
            } else if !log.selectedToppings.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 8) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.teaBrown)
                        Text("加料")
                            .font(.headline)
                        Spacer()
                        Text("+\(log.toppingsCalories) kcal")
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Color.caloriesHigh.opacity(0.15))
                            .foregroundColor(.caloriesHigh)
                            .clipShape(Capsule())
                    }
                    
                    FlowLayout(spacing: 8) {
                        ForEach(Array(log.selectedToppings).sorted(by: { $0.rawValue < $1.rawValue })) { topping in
                            HStack(spacing: 4) {
                                Text(topping.displayName)
                                    .font(.subheadline)
                                Text("\(topping.calories)")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color.gray.opacity(0.08))
                            .clipShape(Capsule())
                        }
                    }
                }
                .padding(20)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
        }
    }
    
    // MARK: - Taste Profile Card
    
    private var tasteProfileCard: some View {
        let tasteEntries = tasteDisplayEntries(for: log)
        
        return Group {
            if isEditing {
                TasteProfileSection(
                    tasteTexture: $editedTasteTexture,
                    tasteTea: $editedTasteTea,
                    tasteMilk: $editedTasteMilk,
                    tasteSweetness: $editedTasteSweetness,
                    tasteIce: $editedTasteIce,
                    tasteSmoothness: $editedTasteSmoothness,
                    tasteAroma: $editedTasteAroma
                )
            } else if !tasteEntries.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 8) {
                        Image(systemName: "chart.bar.fill")
                            .foregroundColor(.teaBrown)
                        Text("風味評鑑")
                            .font(.headline)
                    }
                    
                    ForEach(tasteEntries, id: \.title) { entry in
                        HStack {
                            HStack(spacing: 6) {
                                Image(systemName: entry.icon)
                                    .font(.caption)
                                    .foregroundColor(.teaBrown)
                                    .frame(width: 16)
                                Text(entry.title)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Text(entry.value)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.teaBrown.opacity(0.1))
                                .clipShape(Capsule())
                        }
                    }
                }
                .padding(20)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
        }
    }
    
    private struct TasteEntry {
        let title: String
        let icon: String
        let value: String
    }
    
    private func tasteDisplayEntries(for log: DrinkLog) -> [TasteEntry] {
        var entries: [TasteEntry] = []
        for dim in TasteProfile.allDimensions {
            let raw: String
            switch dim.title {
            case "配料口感": raw = log.tasteTexture
            case "茶味":     raw = log.tasteTea
            case "奶味":     raw = log.tasteMilk
            case "甜度感受": raw = log.tasteSweetness
            case "冰塊感受": raw = log.tasteIce
            case "順口度":   raw = log.tasteSmoothness
            case "香氣":     raw = log.tasteAroma
            default:        raw = ""
            }
            guard !raw.isEmpty else { continue }
            if let label = dim.options.first(where: { $0.value == raw })?.label {
                entries.append(TasteEntry(title: dim.title, icon: dim.icon, value: label))
            }
        }
        return entries
    }
    
    // MARK: - Consumer Experience Card
    
    private var consumerExperienceCard: some View {
        let expEntries = expDisplayEntries(for: log)
        
        return Group {
            if isEditing {
                ConsumerExperienceSection(
                    expCostPerformance: $editedExpCostPerformance,
                    expOccasion: $editedExpOccasion,
                    expRepurchase: $editedExpRepurchase,
                    expPortion: $editedExpPortion,
                    expWaitTime: $editedExpWaitTime
                )
            } else if !expEntries.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 8) {
                        Image(systemName: "bag.fill")
                            .foregroundColor(.teaBrown)
                        Text("消費體驗")
                            .font(.headline)
                    }
                    
                    ForEach(expEntries, id: \.title) { entry in
                        HStack {
                            HStack(spacing: 6) {
                                Image(systemName: entry.icon)
                                    .font(.caption)
                                    .foregroundColor(.teaBrown)
                                    .frame(width: 16)
                                Text(entry.title)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Text(entry.value)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.teaBrown.opacity(0.1))
                                .clipShape(Capsule())
                        }
                    }
                }
                .padding(20)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
        }
    }
    
    private func expDisplayEntries(for log: DrinkLog) -> [TasteEntry] {
        var entries: [TasteEntry] = []
        let fields: [(String, String, String)] = [
            ("CP 值", "dollarsign.circle", log.expCostPerformance),
            ("飲用情境", "location.fill", log.expOccasion),
            ("再回購？", "arrow.counterclockwise", log.expRepurchase),
            ("份量", "cup.and.saucer.fill", log.expPortion),
            ("等待時長", "clock", log.expWaitTime),
        ]
        for (title, icon, raw) in fields {
            guard !raw.isEmpty else { continue }
            if let dim = ConsumerExperience.allDimensions.first(where: { $0.title == title }),
               let label = dim.options.first(where: { $0.value == raw })?.label {
                entries.append(TasteEntry(title: title, icon: icon, value: label))
            }
        }
        return entries
    }
    
    private var deleteButton: some View {
        Button(role: .destructive) {
            showDeleteConfirmation = true
        } label: {
            HStack {
                Image(systemName: "trash")
                Text("刪除此筆紀錄")
            }
            .font(.subheadline)
            .foregroundColor(.red)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Color.red.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
    
    // MARK: - Actions
    
    private func saveChanges() {
        if isCustomDrink {
            // 自訂飲料：直接更新快照資料
            log.drinkName = editedName
            log.brandName = editedBrand
            log.caloriesSnapshot = (Int(editedCalories) ?? 0) + Topping.totalCalories(editedToppings)
            
            if let sugar = Double(editedSugarSnapshot) {
                log.sugarSnapshot = sugar
            } else {
                log.sugarSnapshot = nil
            }
            
            if let caffeine = Int(editedCaffeineSnapshot) {
                log.caffeineSnapshot = caffeine
                log.hasCaffeineSnapshot = caffeine > 0
            } else {
                log.caffeineSnapshot = nil
                // 如果清除了咖啡因數值，是否要設為 false? 這裡假設如果有填寫就是有，沒填寫如果原本有就保留？
                // 不，自訂編輯時應該明確。如果為空，視為無數據或無咖啡因？
                // 為簡單起見，依賴 hasCaffeineSnapshot 邏輯：手動輸入 > 0 即 true
                log.hasCaffeineSnapshot = false 
            }
            
        } else {
            // 圖鑑飲料：重新計算熱量（含配料）
            if let drink = DrinkService.shared.getDrink(byId: log.drinkId) {
                log.caloriesSnapshot = drink.calories(for: editedSugar) + Topping.totalCalories(editedToppings)
            } else if editedToppings != log.selectedToppings {
                // 找不到原始飲料但配料有變，只更新配料差異
                let oldToppingCal = log.toppingsCalories
                let newToppingCal = Topping.totalCalories(editedToppings)
                log.caloriesSnapshot = log.caloriesSnapshot - oldToppingCal + newToppingCal
            }
        }
        
        log.rating = editedRating
        log.comment = editedComment
        log.selectedSugar = editedSugar
        log.selectedIce = editedIce
        log.toppingsSnapshot = Topping.serialize(editedToppings)
        log.tasteTexture = editedTasteTexture
        log.tasteTea = editedTasteTea
        log.tasteMilk = editedTasteMilk
        log.tasteSweetness = editedTasteSweetness
        log.tasteIce = editedTasteIce
        log.tasteSmoothness = editedTasteSmoothness
        log.tasteAroma = editedTasteAroma
        log.expCostPerformance = editedExpCostPerformance
        log.expOccasion = editedExpOccasion
        log.expRepurchase = editedExpRepurchase
        log.expPortion = editedExpPortion
        log.expWaitTime = editedExpWaitTime
        log.createdAt = editedDate
        log.updatedAt = Date()
        
        do {
            try modelContext.save()
            HapticManager.shared.success()
        } catch {
            HapticManager.shared.error()
        }
    }
    
    private func deleteLog() {
        modelContext.delete(log)
        HapticManager.shared.success()
        dismiss()
    }
    
    private func editNutritionInput(title: String, text: Binding<String>, keyboardType: UIKeyboardType, isValid: Bool) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
            
            VStack(spacing: 4) {
                TextField("0", text: text)
                    .keyboardType(keyboardType)
                    .textFieldStyle(.plain)
                    .multilineTextAlignment(.center)
                    .padding(8)
                    .background(isValid ? Color.gray.opacity(0.1) : Color.red.opacity(0.05))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(isValid ? Color.clear : Color.red, lineWidth: 1)
                    )
                
                if !isValid {
                    Text("上限 9999")
                        .font(.caption2)
                        .foregroundColor(.red)
                        .transition(.opacity)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .top)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy 年 M 月 d 日 HH:mm"
        return formatter.string(from: date)
    }
}

#Preview {
    NavigationStack {
        DiaryDetailView(
            log: DrinkLog(
                drinkId: "test",
                brandId: "50lan",
                userId: "user1",
                selectedSugar: .sugar50,
                selectedIce: .lessIce,
                rating: 4,
                comment: "很好喝！",
                drinkName: "四季春青茶",
                brandName: "50嵐",
                caloriesSnapshot: 80,
                hasCaffeineSnapshot: true
            )
        )
    }
    .modelContainer(for: DrinkLog.self, inMemory: true)
}
