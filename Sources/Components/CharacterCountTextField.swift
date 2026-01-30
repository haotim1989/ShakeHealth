import SwiftUI

/// 字數限制輸入框 (20字限制)
struct CharacterCountTextField: View {
    @Binding var text: String
    let maxLength: Int
    let placeholder: String
    
    init(
        text: Binding<String>,
        maxLength: Int = Constants.maxCommentLength,
        placeholder: String = "輸入您的感想..."
    ) {
        self._text = text
        self.maxLength = maxLength
        self.placeholder = placeholder
    }
    
    private var remainingCount: Int {
        maxLength - text.count
    }
    
    private var isOverLimit: Bool {
        text.count > maxLength
    }
    
    private var isNearLimit: Bool {
        remainingCount <= 5 && remainingCount > 0
    }
    
    var body: some View {
        VStack(alignment: .trailing, spacing: 6) {
            TextField(placeholder, text: $text, axis: .vertical)
                .lineLimit(2...4)
                .padding(12)
                .background(backgroundColor)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(borderColor, lineWidth: isOverLimit ? 2 : 1)
                )
            
            HStack {
                if isOverLimit {
                    Text("已超過字數限制")
                        .font(.caption)
                        .foregroundColor(.red)
                }
                
                Spacer()
                
                Text("\(text.count)/\(maxLength)")
                    .font(.caption)
                    .fontWeight(isOverLimit ? .semibold : .regular)
                    .foregroundColor(counterColor)
            }
        }
    }
    
    private var backgroundColor: Color {
        if isOverLimit {
            return Color.red.opacity(0.08)
        } else if isNearLimit {
            return Color.orange.opacity(0.05)
        }
        return Color.gray.opacity(0.08)
    }
    
    private var borderColor: Color {
        if isOverLimit {
            return .red
        } else if isNearLimit {
            return .orange.opacity(0.5)
        }
        return Color.gray.opacity(0.2)
    }
    
    private var counterColor: Color {
        if isOverLimit {
            return .red
        } else if isNearLimit {
            return .orange
        }
        return .secondary
    }
}

#Preview {
    @Previewable @State var text = "這是一個測試"
    CharacterCountTextField(text: $text)
        .padding()
}
