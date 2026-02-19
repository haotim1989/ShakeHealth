import SwiftUI

/// 飲料卡片 (用於隨機推薦結果)
struct DrinkResultCard: View {
    let drink: Drink
    let criteria: FilterCriteria  // 新增：用於計算正確熱量
    let onFindStore: () -> Void
    let onPickAgain: () -> Void
    let onShowFilter: () -> Void
    
    @State private var appeared = false
    
    /// 根據篩選條件計算的熱量
    private var displayCalories: Int {
        criteria.caloriesForDrink(drink)
    }
    
    /// 顯示的甜度標籤（如果有選擇）
    private var sugarLabel: String? {
        criteria.selectedSugarLevel?.rawValue
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // 1. 視覺核心區
            VStack(spacing: 20) {
                // 品牌標籤
                if let brand = drink.brand {
                    Text(brand.name)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.teaBrown)
                        .clipShape(Capsule())
                        .shadow(color: .teaBrown.opacity(0.3), radius: 4, y: 2)
                }
                
                // 飲料圖示
                ZStack {
                    Circle()
                        .fill(Color.white)
                        .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)
                    
                    CategoryIconView(category: drink.category, size: 64)
                }
                .frame(width: 120, height: 120)
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 32)
            .padding(.bottom, 24)
            // 背景裝飾
            .background(
                ZStack {
                    Color.milkCream.opacity(0.3)
                    Circle()
                        .fill(Color.white)
                        .frame(width: 300, height: 300)
                        .blur(radius: 60)
                        .offset(y: -50)
                }
            )
            
            // 2. 資訊區
            VStack(spacing: 24) {
                VStack(spacing: 8) {
                    Text(drink.name)
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)
                    
                    Text(drink.category.rawValue)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                // 資訊膠囊列
                HStack(spacing: 12) {
                    // 熱量
                    InfoPill(icon: "flame.fill", text: "\(displayCalories) kcal", color: .orange)
                    
                    // 咖啡因
                    if let hasCaffeine = drink.hasCaffeine {
                        InfoPill(
                            icon: "cup.and.saucer.fill",
                            text: hasCaffeine ? "含咖啡因" : "無咖啡因",
                            color: hasCaffeine ? .brown : .green
                        )
                    } else {
                        InfoPill(
                            icon: "cup.and.saucer.fill",
                            text: "資料不足",
                            color: .gray
                        )
                    }
                    
                    // 甜度
                    if let sugar = sugarLabel {
                        InfoPill(icon: "cube.fill", text: sugar, color: .pink)
                    }
                }
                
                Divider()
                    .padding(.vertical, 8)
                
                // 3. 按鈕區
                // 3. 按鈕區
                VStack(spacing: 12) {
                    // 1. 再抽一次 (移到最上方，主要大按鈕)
                    Button(action: onPickAgain) {
                        HStack {
                            Image(systemName: "arrow.clockwise")
                            Text("再抽一次")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.teaBrown)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: .teaBrown.opacity(0.3), radius: 4, x: 0, y: 2)
                    }

                    // 2. 下方並排按鈕 (尋找店家 + 篩選條件)
                    HStack(spacing: 12) {
                        // 尋找店家
                        Button(action: onFindStore) {
                            HStack {
                                Image(systemName: "map.fill")
                                Text("尋找店家")
                            }
                            .font(.headline)
                            .foregroundColor(.teaBrown)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.white)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.teaBrown, lineWidth: 1)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                        
                        // 設定篩選條件
                        Button(action: onShowFilter) {
                            HStack(spacing: 4) {
                                Image(systemName: "slider.horizontal.3")
                                Text(criteria.activeFilterCount > 0 ? "篩選(\(criteria.activeFilterCount))" : "篩選")
                            }
                            .font(.headline)
                            .foregroundColor(.teaBrown)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.white)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.teaBrown, lineWidth: criteria.activeFilterCount > 0 ? 2 : 1)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                    }
                }
            }
            .padding(24)
            .background(Color.white)
        }
        .clipShape(RoundedRectangle(cornerRadius: 32))
        .shadow(color: .black.opacity(0.08), radius: 25, y: 10)
        .scaleEffect(appeared ? 1 : 0.8)
        .opacity(appeared ? 1 : 0)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                appeared = true
            }
        }
    }
}

// MARK: - Helper Views

struct InfoPill: View {
    let icon: String
    let text: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.subheadline)
            Text(text)
                .font(.headline)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(color.opacity(0.1))
        .foregroundColor(color)
        .clipShape(Capsule())
    }
}

#Preview {
    DrinkResultCard(
        drink: Drink.sampleDrinks[1],
        criteria: FilterCriteria(),
        onFindStore: {},
        onPickAgain: {},
        onShowFilter: {}
    )
    .padding()
    .background(Color.backgroundPrimary)
}
