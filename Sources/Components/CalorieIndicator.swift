import SwiftUI

/// 熱量指示器
struct CalorieIndicator: View {
    let calories: Int
    let style: Style
    
    enum Style {
        case compact    // 僅數字
        case badge      // 帶背景色 badge
        case detailed   // 帶圖示與單位
    }
    
    init(calories: Int, style: Style = .badge) {
        self.calories = calories
        self.style = style
    }
    
    private var indicatorColor: Color {
        Color.forCalories(calories)
    }
    
    var body: some View {
        switch style {
        case .compact:
            Text("\(calories)")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(indicatorColor)
            
        case .badge:
            Text("\(calories) kcal")
                .font(.caption)
                .fontWeight(.semibold)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(indicatorColor.opacity(0.15))
                .foregroundColor(indicatorColor)
                .clipShape(Capsule())
            
        case .detailed:
            HStack(spacing: 4) {
                Image(systemName: "flame.fill")
                    .font(.caption)
                Text("\(calories) kcal")
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }
            .foregroundColor(indicatorColor)
        }
    }
}

/// 咖啡因圖示
struct CaffeineIcon: View {
    let hasCaffeine: Bool
    let showLabel: Bool
    
    init(hasCaffeine: Bool, showLabel: Bool = false) {
        self.hasCaffeine = hasCaffeine
        self.showLabel = showLabel
    }
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: hasCaffeine ? "cup.and.saucer.fill" : "leaf.fill")
                .font(.caption)
                .foregroundColor(hasCaffeine ? .brown : .green)
            
            if showLabel {
                Text(hasCaffeine ? "含咖啡因" : "無咖啡因")
                    .font(.caption)
                    .foregroundColor(hasCaffeine ? .brown : .green)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            (hasCaffeine ? Color.brown : Color.green).opacity(0.1)
        )
        .clipShape(Capsule())
    }
}

#Preview("Calories") {
    VStack(spacing: 20) {
        CalorieIndicator(calories: 150, style: .compact)
        CalorieIndicator(calories: 350, style: .badge)
        CalorieIndicator(calories: 550, style: .detailed)
    }
    .padding()
}

#Preview("Caffeine") {
    VStack(spacing: 20) {
        CaffeineIcon(hasCaffeine: true, showLabel: true)
        CaffeineIcon(hasCaffeine: false, showLabel: true)
    }
    .padding()
}
