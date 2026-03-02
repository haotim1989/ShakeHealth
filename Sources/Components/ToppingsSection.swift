import SwiftUI

/// 配料選擇區（共用元件）
/// 依據紅🔴 / 黃🟡 / 綠🟢 熱量燈區分組顯示
struct ToppingsSection: View {
    @Binding var selectedToppings: Set<Topping>
    @State private var isExpanded = false
    
    /// 配料總熱量
    var totalCalories: Int {
        Topping.totalCalories(selectedToppings)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 標題列（整條可點擊）
            Button {
                withAnimation(.easeInOut(duration: 0.25)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(.teaBrown)
                    Text("加料（選填）")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text("熱量僅供參考")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    if !selectedToppings.isEmpty && !isExpanded {
                        Text("+\(totalCalories) kcal")
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Color.caloriesHigh.opacity(0.15))
                            .foregroundColor(.caloriesHigh)
                            .clipShape(Capsule())
                    }
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            
            if isExpanded {
                // 已選配料熱量小計
                if !selectedToppings.isEmpty {
                    HStack {
                        Spacer()
                        Text("+\(totalCalories) kcal")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.caloriesHigh)
                    }
                }
                
                // 各燈區
                ForEach(Topping.grouped, id: \.tier) { group in
                    tierSection(group.tier, toppings: group.toppings)
                }
            }
        }
        .animation(.easeInOut(duration: 0.2), value: selectedToppings)
        .padding(16)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    // MARK: - Tier Section
    
    private func tierSection(_ tier: Topping.Tier, toppings: [Topping]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            // 燈區標題
            HStack(spacing: 6) {
                Circle()
                    .fill(tierColor(tier))
                    .frame(width: 10, height: 10)
                
                Text(tier.displayName)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(tierColor(tier))
                
                Text(tier.calorieRange)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            // 配料 Chips (使用 FlowLayout)
            FlowLayout(spacing: 8) {
                ForEach(toppings) { topping in
                    toppingChip(topping)
                }
            }
        }
    }
    
    // MARK: - Topping Chip
    
    private func toppingChip(_ topping: Topping) -> some View {
        let isSelected = selectedToppings.contains(topping)
        
        return Button {
            withAnimation(.easeInOut(duration: 0.15)) {
                if isSelected {
                    selectedToppings.remove(topping)
                } else {
                    selectedToppings.insert(topping)
                }
            }
            HapticManager.shared.light()
        } label: {
            HStack(spacing: 4) {
                Text(topping.displayName)
                    .font(.subheadline)
                
                Text("\(topping.calories)")
                    .font(.caption2)
                    .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? tierColor(topping.tier) : Color.gray.opacity(0.08))
            .foregroundColor(isSelected ? .white : .primary)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(isSelected ? Color.clear : Color.gray.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Helpers
    
    private func tierColor(_ tier: Topping.Tier) -> Color {
        switch tier {
        case .red:    return .caloriesHigh
        case .yellow: return .caloriesMedium
        case .green:  return .green
        }
    }
}

#Preview {
    ToppingsSection(selectedToppings: .constant([.bobaPearl, .pudding]))
        .padding()
        .background(Color.backgroundPrimary)
}
