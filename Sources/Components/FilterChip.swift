import SwiftUI

/// 篩選標籤 Chip
struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(isSelected ? Color.teaBrown : Color.gray.opacity(0.1))
                .foregroundColor(isSelected ? .white : .primary)
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(isSelected ? Color.clear : Color.gray.opacity(0.3), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}

/// 可選擇的 Chip 群組
struct FilterChipGroup<Item: Hashable & Identifiable>: View where Item: CustomStringConvertible {
    let items: [Item]
    @Binding var selectedItems: Set<Item>
    let allowsMultipleSelection: Bool
    
    init(
        items: [Item],
        selectedItems: Binding<Set<Item>>,
        allowsMultipleSelection: Bool = true
    ) {
        self.items = items
        self._selectedItems = selectedItems
        self.allowsMultipleSelection = allowsMultipleSelection
    }
    
    var body: some View {
        FlowLayout(spacing: 8) {
            ForEach(items) { item in
                FilterChip(
                    title: item.description,
                    isSelected: selectedItems.contains(item)
                ) {
                    toggleSelection(item)
                }
            }
        }
    }
    
    private func toggleSelection(_ item: Item) {
        if selectedItems.contains(item) {
            selectedItems.remove(item)
        } else {
            if !allowsMultipleSelection {
                selectedItems.removeAll()
            }
            selectedItems.insert(item)
        }
    }
}

/// 流式佈局 (Chips 自動換行)
struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrangeSubviews(proposal: proposal, subviews: subviews)
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrangeSubviews(proposal: proposal, subviews: subviews)
        
        for (index, frame) in result.frames.enumerated() {
            subviews[index].place(
                at: CGPoint(x: bounds.minX + frame.minX, y: bounds.minY + frame.minY),
                proposal: ProposedViewSize(frame.size)
            )
        }
    }
    
    private func arrangeSubviews(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, frames: [CGRect]) {
        let maxWidth = proposal.width ?? .infinity
        var frames: [CGRect] = []
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0
        var totalHeight: CGFloat = 0
        var totalWidth: CGFloat = 0
        
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            
            if currentX + size.width > maxWidth && currentX > 0 {
                currentX = 0
                currentY += lineHeight + spacing
                lineHeight = 0
            }
            
            frames.append(CGRect(x: currentX, y: currentY, width: size.width, height: size.height))
            
            lineHeight = max(lineHeight, size.height)
            currentX += size.width + spacing
            totalWidth = max(totalWidth, currentX - spacing)
        }
        
        totalHeight = currentY + lineHeight
        
        return (CGSize(width: totalWidth, height: totalHeight), frames)
    }
}

#Preview {
    FilterChip(title: "奶茶類", isSelected: true) {}
        .padding()
}
