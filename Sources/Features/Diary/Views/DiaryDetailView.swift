import SwiftUI
import SwiftData

/// 日記詳情頁面
struct DiaryDetailView: View {
    @Bindable var log: DrinkLog
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var isEditing = false
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
        self._editedCalories = State(initialValue: String(log.caloriesSnapshot))
        self._editedSugarSnapshot = State(initialValue: log.sugarSnapshot.map { String(format: "%.0f", $0) } ?? "")
        self._editedCaffeineSnapshot = State(initialValue: log.caffeineSnapshot.map { String($0) } ?? "")
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
    
    /// 目前顯示的熱量 (編輯模式下會即時計算)
    private var currentDisplayCalories: Int {
        if isEditing {
            // 嘗試取得原始飲料資料來計算新的熱量
            if let drink = DrinkService.shared.getDrink(byId: log.drinkId) {
                return drink.calories(for: editedSugar)
            }
            // 如果找不到原始資料 (可能是自訂飲料)，則回傳原本的快照
            // 注意：自訂飲料目前無法根據甜度調整熱量，除非我們在 DrinkLog 存了更多資訊
            return log.caloriesSnapshot
        } else {
            return log.caloriesSnapshot
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // 飲料資訊卡片
                drinkInfoCard
                
                // 規格資訊
                specificationCard
                
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
    }
    
    // MARK: - Subviews
    
    private var drinkInfoCard: some View {
        VStack(spacing: 16) {
            // 飲料圖示
            ZStack {
                Circle()
                    .fill(Color.milkCream)
                    .frame(width: 80, height: 80)
                
                Image(systemName: "cup.and.saucer.fill")
                    .font(.system(size: 35))
                    .foregroundColor(.teaBrown)
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
                    
                    if log.hasCaffeineSnapshot || isCustomDrink { // 自訂飲料也可能顯示
                        let caffeine = log.caffeineSnapshot ?? (log.hasCaffeineSnapshot ? -1 : 0)
                        if caffeine > 0 || log.hasCaffeineSnapshot {
                            CaffeineIcon(hasCaffeine: true, showLabel: true)
                        }
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
            log.caloriesSnapshot = Int(editedCalories) ?? 0
            
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
            // 圖鑑飲料：如果甜度改變，使用原始飲料資料重新計算熱量
            if editedSugar != log.selectedSugar {
                if let drink = DrinkService.shared.getDrink(byId: log.drinkId) {
                    log.caloriesSnapshot = drink.calories(for: editedSugar)
                }
            }
        }
        
        log.rating = editedRating
        log.comment = editedComment
        log.selectedSugar = editedSugar
        log.selectedIce = editedIce
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
