import SwiftUI

/// 飲料卡片 (用於隨機推薦結果)
struct DrinkResultCard: View {
    let drink: Drink
    let onFindStore: () -> Void
    let onPickAgain: () -> Void
    
    @State private var appeared = false
    
    var body: some View {
        VStack(spacing: 0) {
            // 頂部圖片區
            ZStack {
                // 背景漸層
                LinearGradient(
                    colors: [Color.milkCream, Color.backgroundPrimary],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                
                // 飲料圖示 (之後可替換為實際圖片)
                VStack(spacing: 12) {
                    Image(systemName: categoryIcon)
                        .font(.system(size: 60))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.teaBrown, .teaBrown.opacity(0.6)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                    
                    // 品牌標籤
                    if let brand = drink.brand {
                        Text(brand.name)
                            .font(.caption)
                            .fontWeight(.medium)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 4)
                            .background(Color.teaBrown.opacity(0.1))
                            .clipShape(Capsule())
                    }
                }
            }
            .frame(height: 180)
            
            // 資訊區
            VStack(spacing: 16) {
                // 飲料名稱
                Text(drink.name)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                
                // 營養資訊
                HStack(spacing: 16) {
                    CalorieIndicator(calories: drink.baseCalories, style: .detailed)
                    CaffeineIcon(hasCaffeine: drink.hasCaffeine, showLabel: true)
                }
                
                // 分類標籤
                Text(drink.category.rawValue)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Divider()
                    .padding(.vertical, 8)
                
                // 行動按鈕
                VStack(spacing: 12) {
                    // 尋找店家
                    Button(action: onFindStore) {
                        HStack {
                            Image(systemName: "map.fill")
                            Text("尋找店家")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.teaBrown)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    
                    // 再抽一次
                    Button(action: onPickAgain) {
                        HStack {
                            Image(systemName: "arrow.clockwise")
                            Text("再抽一次")
                        }
                        .font(.headline)
                        .foregroundColor(.teaBrown)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.teaBrown.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
            }
            .padding(24)
            .background(Color.white)
        }
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .shadow(color: .black.opacity(0.1), radius: 20, y: 10)
        .scaleEffect(appeared ? 1 : 0.8)
        .opacity(appeared ? 1 : 0)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                appeared = true
            }
        }
    }
    
    private var categoryIcon: String {
        switch drink.category {
        case .milkTea: return "cup.and.saucer.fill"
        case .pureTea: return "leaf.fill"
        case .fruitTea: return "🍊".isEmpty ? "leaf" : "drop.fill" // Fallback
        case .coffee: return "mug.fill"
        case .fresh: return "drop.fill"
        case .special: return "sparkles"
        }
    }
}

#Preview {
    DrinkResultCard(
        drink: Drink.sampleDrinks[1],
        onFindStore: {},
        onPickAgain: {}
    )
    .padding()
    .background(Color.backgroundPrimary)
}
