import SwiftUI
import SwiftData

/// 新增日記 Modal
struct AddToLogModal: View {
    let drink: Drink
    let onDismiss: () -> Void
    let onSave: (SugarLevel, IceLevel, Int, String) -> Void
    
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var userManager: UserManager
    
    @State private var selectedSugar: SugarLevel = .sugar50
    @State private var selectedIce: IceLevel = .lessIce
    @State private var rating: Int = 3
    @State private var comment: String = ""
    @State private var showCalorieWarning = false
    
    // 日期選擇 (Pro 功能)
    @State private var selectedDate: Date = Date()
    @State private var showDatePicker = false
    
    // Paywall
    @State private var showPaywall = false
    
    private var isValidForm: Bool {
        rating >= 1 && rating <= 5 && comment.count <= Constants.maxCommentLength
    }
    
    private var estimatedCalories: Int {
        drink.calories(for: selectedSugar)
    }
    
    private var isBackdating: Bool {
        !Calendar.current.isDateInToday(selectedDate)
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // 日期選擇 (Pro 功能)
                    dateSection
                    
                    // 飲料資訊卡片
                    drinkInfoCard
                    
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
            .navigationTitle("新增紀錄")
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
    
    // MARK: - Subviews
    
    private var drinkInfoCard: some View {
        HStack(spacing: 16) {
            // 圖示
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.milkCream)
                    .frame(width: 60, height: 60)
                
                Image(systemName: "cup.and.saucer.fill")
                    .font(.title2)
                    .foregroundColor(.teaBrown)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(drink.name)
                    .font(.headline)
                
                if let brand = drink.brand {
                    Text(brand.name)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                // 咖啡因標示
                if let hasCaffeine = drink.hasCaffeine, hasCaffeine {
                    CaffeineIcon(hasCaffeine: true, showLabel: true)
                }
            }
            
            Spacer()
            
            // 預估熱量
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(estimatedCalories)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(Color.forCalories(estimatedCalories))
                Text("kcal")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(16)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 5, y: 2)
    }
    
    private var specificationSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("規格選擇")
                .font(.headline)
            
            // 甜度
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("甜度")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    if showCalorieWarning {
                        Text("• 熱量會變化")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(drink.availableSugarLevels) { level in
                            specButton(
                                title: level.shortName,
                                isSelected: selectedSugar == level
                            ) {
                                selectedSugar = level
                                showCalorieWarning = true
                                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                    showCalorieWarning = false
                                }
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
                        ForEach(drink.availableIceLevels) { level in
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
        // 建立日記紀錄
        let log = DrinkLog(
            drinkId: drink.id,
            brandId: drink.brandId,
            userId: appState.userId,
            selectedSugar: selectedSugar,
            selectedIce: selectedIce,
            rating: rating,
            comment: comment,
            drinkName: drink.name,
            brandName: drink.brand?.name ?? "",
            caloriesSnapshot: estimatedCalories,
            hasCaffeineSnapshot: drink.hasCaffeine ?? false,
            createdAt: selectedDate  // 使用選擇的日期
        )
        
        modelContext.insert(log)
        
        do {
            try modelContext.save()
            
            HapticManager.shared.success()
            onSave(selectedSugar, selectedIce, rating, comment)
        } catch {
            HapticManager.shared.error()
        }
    }
}

#Preview {
    AddToLogModal(
        drink: Drink.sampleDrinks[0],
        onDismiss: {},
        onSave: { _, _, _, _ in }
    )
    .environmentObject(AppState())
    .environmentObject(UserManager.shared)
}

