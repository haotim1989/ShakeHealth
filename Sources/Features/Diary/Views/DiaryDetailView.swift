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
    @State private var showDeleteConfirmation = false
    
    init(log: DrinkLog) {
        self.log = log
        self._editedRating = State(initialValue: log.rating)
        self._editedComment = State(initialValue: log.comment)
        self._editedSugar = State(initialValue: log.selectedSugar)
        self._editedIce = State(initialValue: log.selectedIce)
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
                Text(log.drinkName)
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text(log.brandName)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            // 熱量與咖啡因
            HStack(spacing: 12) {
                CalorieIndicator(calories: log.caloriesSnapshot, style: .detailed)
                
                if log.hasCaffeineSnapshot {
                    CaffeineIcon(hasCaffeine: true, showLabel: true)
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
        Menu {
            ForEach(ShareService.Platform.allCases) { platform in
                Button {
                    ShareService.share(log: log, to: platform)
                } label: {
                    Label(platform.rawValue, systemImage: platform.iconName)
                }
            }
            
            Divider()
            
            Button {
                ShareService.shareViaSystem(message: ShareService.generateShareMessage(for: log))
            } label: {
                Label("其他方式...", systemImage: "ellipsis.circle")
            }
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
        // 驗證評論字數 (限制 30 字)
        if editedComment.count > 30 {
            editedComment = String(editedComment.prefix(30))
        }
        
        // 如果甜度改變，重新計算熱量
        if editedSugar != log.selectedSugar {
            // 先反推基準熱量（以原本甜度的 multiplier 反推）
            let originalMultiplier = log.selectedSugar.multiplier
            let baseCalories = Double(log.caloriesSnapshot) / originalMultiplier
            // 用新甜度計算熱量
            let newCalories = Int(baseCalories * editedSugar.multiplier)
            log.caloriesSnapshot = newCalories
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
