import SwiftUI
import SwiftData

/// 自訂飲料 Modal - 讓用戶新增圖鑑中沒有的飲料
struct CustomDrinkModal: View {
    let onDismiss: () -> Void
    let onSave: () -> Void
    
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var userManager: UserManager
    
    // 飲料資訊
    @State private var drinkName: String = ""
    @State private var brandName: String = ""
    @State private var estimatedCalories: String = ""
    @State private var estimatedSugar: String = ""
    @State private var estimatedCaffeine: String = ""
    
    // 規格選擇
    @State private var selectedSugar: SugarLevel = .sugar50
    @State private var selectedIce: IceLevel = .lessIce
    
    // 評分與感想
    @State private var rating: Int = 3
    @State private var comment: String = ""
    
    // 日期選擇 (Pro 功能)
    @State private var selectedDate: Date = Date()
    @State private var showDatePicker = false
    
    // Paywall
    @State private var showPaywall = false
    
    // 可選的糖度與冰塊
    private let allSugarLevels: [SugarLevel] = [.sugar0, .sugar30, .sugar50, .sugar70, .sugar100]
    private let allIceLevels: [IceLevel] = [.hot, .noIce, .lightIce, .lessIce, .normalIce]
    
    private var isValidForm: Bool {
        !drinkName.trimmingCharacters(in: .whitespaces).isEmpty &&
        rating >= 1 && rating <= 5 &&
        comment.count <= Constants.maxCommentLength &&
        (Int(estimatedCalories) ?? 0) <= 9999 &&
        (Double(estimatedSugar) ?? 0) <= 9999 &&
        (Int(estimatedCaffeine) ?? 0) <= 9999
    }
    
    private var caloriesInt: Int {
        Int(estimatedCalories) ?? 0
    }
    
    private var isBackdating: Bool {
        !Calendar.current.isDateInToday(selectedDate)
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // 日期選擇 (Pro 功能)
                    dateSection
                    
                    // 飲料資訊輸入
                    drinkInfoSection
                    
                    // 規格選擇
                    specificationSection
                    
                    // 評分
                    ratingSection
                    
                    // 評論
                    commentSection
                }
                .padding(20)
            }
            .scrollDismissesKeyboard(.immediately)
            .onTapGesture {
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            }
            .background(Color.backgroundPrimary)
            .navigationTitle("自訂飲料")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("取消") {
                        onDismiss()
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button("儲存") {
                        attemptSave()
                    }
                    .fontWeight(.semibold)
                    .disabled(!isValidForm)
                }
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView()
                    .environmentObject(userManager)
            }
        }
    }
    
    // MARK: - Date Section
    
    private var dateSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "calendar")
                    .foregroundColor(.teaBrown)
                Text("記錄日期")
                    .font(.headline)
                
                Spacer()
            }
            
            Button {
                showDatePicker.toggle()
            } label: {
                HStack {
                    Text(selectedDate, style: .date)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    if isBackdating {
                        Text("補登")
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color.orange.opacity(0.2))
                            .foregroundColor(.orange)
                            .clipShape(Capsule())
                    }
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color.gray.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .buttonStyle(.plain)
            
            if showDatePicker {
                DatePicker(
                    "選擇日期",
                    selection: $selectedDate,
                    in: ...Date(),
                    displayedComponents: .date
                )
                .datePickerStyle(.graphical)
                .labelsHidden()
            }
        }
        .padding(16)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    // MARK: - Drink Info Section
    
    private var drinkInfoSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "cup.and.saucer.fill")
                    .foregroundColor(.teaBrown)
                Text("飲料資訊")
                    .font(.headline)
            }
            
            // 飲料名稱
            VStack(alignment: .leading, spacing: 6) {
                Text("飲料名稱 *")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                TextField("例如：珍珠奶茶", text: $drinkName)
                    .textFieldStyle(.plain)
                    .padding(12)
                    .background(Color.gray.opacity(0.05))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            
            // 品牌名稱
            VStack(alignment: .leading, spacing: 6) {
                Text("品牌 (選填)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                TextField("例如：50 嵐", text: $brandName)
                    .textFieldStyle(.plain)
                    .padding(12)
                    .background(Color.gray.opacity(0.05))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            
            // 營養標示
            VStack(alignment: .leading, spacing: 12) {
                Text("營養標示 (選填)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                HStack(alignment: .top, spacing: 12) {
                    // 熱量
                    nutritionInput(
                        title: "熱量",
                        unit: "kcal",
                        text: $estimatedCalories,
                        isValid: (Int(estimatedCalories) ?? 0) <= 9999
                    )
                    
                    // 糖分
                    nutritionInput(
                        title: "總糖量",
                        unit: "g",
                        text: $estimatedSugar,
                        isValid: (Double(estimatedSugar) ?? 0) <= 9999
                    )
                    
                    // 咖啡因
                    nutritionInput(
                        title: "咖啡因",
                        unit: "mg",
                        text: $estimatedCaffeine,
                        isValid: (Int(estimatedCaffeine) ?? 0) <= 9999
                    )
                }
            }
        }
        .padding(16)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    private func nutritionInput(title: String, unit: String, text: Binding<String>, isValid: Bool) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            VStack(spacing: 4) {
                HStack(spacing: 4) {
                    TextField("0", text: text)
                        .keyboardType(.numberPad) // 糖分如果是小數可能需要 decimalPad，這裡先用 numberPad
                        .textFieldStyle(.plain)
                        .multilineTextAlignment(.trailing)
                    
                    Text(unit)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(10)
                .background(isValid ? Color.gray.opacity(0.05) : Color.red.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
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
    
    // MARK: - Specification Section
    
    private var specificationSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("規格選擇")
                .font(.headline)
            
            // 甜度
            VStack(alignment: .leading, spacing: 8) {
                Text("甜度")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(allSugarLevels, id: \.self) { level in
                            specButton(
                                title: level.shortName,
                                isSelected: selectedSugar == level
                            ) {
                                selectedSugar = level
                            }
                        }
                    }
                }
            }
            
            // 冰塊
            VStack(alignment: .leading, spacing: 8) {
                Text("冰塊")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(allIceLevels, id: \.self) { level in
                            specButton(
                                title: level.rawValue,
                                isSelected: selectedIce == level
                            ) {
                                selectedIce = level
                            }
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    private func specButton(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(isSelected ? Color.teaBrown : Color.gray.opacity(0.1))
                .foregroundColor(isSelected ? .white : .primary)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Rating Section
    
    private var ratingSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("評分")
                .font(.headline)
            
            HStack {
                Spacer()
                StarRatingView(rating: $rating)
                Spacer()
            }
        }
        .padding(16)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    // MARK: - Comment Section
    
    private var commentSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("感想")
                .font(.headline)
            
            CharacterCountTextField(
                text: $comment,
                placeholder: "記錄一下你的感想吧..."
            )
        }
        .padding(16)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    // MARK: - Actions
    
    private func attemptSave() {
        saveLog()
    }
    
    private func saveLog() {
        let trimmedName = drinkName.trimmingCharacters(in: .whitespaces)
        let trimmedBrand = brandName.trimmingCharacters(in: .whitespaces)
        
        // 使用 "custom_" 前綴作為自訂飲料的 ID
        let customDrinkId = "custom_\(UUID().uuidString)"
        let customBrandId = trimmedBrand.isEmpty ? "custom_brand" : "custom_\(trimmedBrand.lowercased().replacingOccurrences(of: " ", with: "_"))"
        
        // 建立日記紀錄
        let log = DrinkLog(
            drinkId: customDrinkId,
            brandId: customBrandId,
            userId: appState.userId,
            selectedSugar: selectedSugar,
            selectedIce: selectedIce,
            rating: rating,
            comment: comment,
            drinkName: trimmedName,
            brandName: trimmedBrand.isEmpty ? "自訂" : trimmedBrand,
            caloriesSnapshot: caloriesInt,
            hasCaffeineSnapshot: (Int(estimatedCaffeine) ?? 0) > 0,
            sugarSnapshot: Double(estimatedSugar),
            caffeineSnapshot: Int(estimatedCaffeine),
            createdAt: selectedDate
        )
        
        modelContext.insert(log)
        
        do {
            try modelContext.save()
            
            HapticManager.shared.success()
            onSave()
        } catch {
            HapticManager.shared.error()
        }
    }
}

#Preview {
    CustomDrinkModal(
        onDismiss: {},
        onSave: {}
    )
    .environmentObject(AppState())
    .environmentObject(UserManager.shared)
}
