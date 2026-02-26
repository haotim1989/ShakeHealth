import SwiftUI

/// 口感風味評鑑區（共用元件）
/// 6 個維度各一行，每行可選擇一個級距
struct TasteProfileSection: View {
    @Binding var tasteTexture: String
    @Binding var tasteTea: String
    @Binding var tasteMilk: String
    @Binding var tasteSweetness: String
    @Binding var tasteIce: String
    @Binding var tasteSmoothness: String
    
    @State private var isExpanded = false
    
    /// 已填寫的維度數量
    private var filledCount: Int {
        [tasteTexture, tasteTea, tasteMilk, tasteSweetness, tasteIce, tasteSmoothness]
            .filter { !$0.isEmpty }.count
    }
    
    private var bindings: [Binding<String>] {
        [$tasteTexture, $tasteTea, $tasteMilk, $tasteSweetness, $tasteIce, $tasteSmoothness]
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 標題列（可展開/摺疊）
            Button {
                withAnimation(.easeInOut(duration: 0.25)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "chart.bar.fill")
                        .foregroundColor(.teaBrown)
                    Text("風味評鑑（選填）")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    if filledCount > 0 && !isExpanded {
                        Text("已填 \(filledCount) 項")
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Color.teaBrown.opacity(0.15))
                            .foregroundColor(.teaBrown)
                            .clipShape(Capsule())
                    }
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            
            // 展開的維度列表
            if isExpanded {
                VStack(spacing: 16) {
                    ForEach(Array(TasteProfile.allDimensions.enumerated()), id: \.offset) { index, dimension in
                        dimensionRow(dimension: dimension, selection: bindings[index])
                    }
                }
            }
        }
        .padding(16)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    // MARK: - Dimension Row
    
    private func dimensionRow(dimension: TasteProfile.Dimension, selection: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            // 維度標題
            HStack(spacing: 6) {
                Image(systemName: dimension.icon)
                    .font(.caption)
                    .foregroundColor(.teaBrown)
                    .frame(width: 16)
                
                Text(dimension.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            
            // 橫向滑動 Chip
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(dimension.options, id: \.value) { option in
                        chipButton(
                            label: option.label,
                            value: option.value,
                            selection: selection
                        )
                    }
                }
            }
        }
    }
    
    // MARK: - Chip Button
    
    private func chipButton(label: String, value: String, selection: Binding<String>) -> some View {
        let isSelected = selection.wrappedValue == value
        
        return Button {
            withAnimation(.easeInOut(duration: 0.15)) {
                if isSelected {
                    selection.wrappedValue = ""  // 取消選擇
                } else {
                    selection.wrappedValue = value
                }
            }
            HapticManager.shared.light()
        } label: {
            Text(label)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(isSelected ? Color.teaBrown : Color.gray.opacity(0.08))
                .foregroundColor(isSelected ? .white : .primary)
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(isSelected ? Color.clear : Color.gray.opacity(0.15), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    TasteProfileSection(
        tasteTexture: .constant(""),
        tasteTea: .constant("tea_rich"),
        tasteMilk: .constant(""),
        tasteSweetness: .constant("sweet_sweet"),
        tasteIce: .constant(""),
        tasteSmoothness: .constant("")
    )
    .padding()
    .background(Color.backgroundPrimary)
}
