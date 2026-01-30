import SwiftUI

/// 搖動動畫視圖
struct ShakeAnimationView: View {
    @Binding var isShaking: Bool
    
    @State private var rotation: Double = 0
    @State private var scale: CGFloat = 1.0
    
    var body: some View {
        VStack(spacing: 24) {
            // 搖搖杯圖示
            ZStack {
                // 背景光暈
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.teaBrown.opacity(0.3), Color.clear],
                            center: .center,
                            startRadius: 40,
                            endRadius: 120
                        )
                    )
                    .frame(width: 200, height: 200)
                    .scaleEffect(isShaking ? 1.2 : 1.0)
                
                // 飲料杯
                Image(systemName: "cup.and.saucer.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.teaBrown, .milkCream],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .rotationEffect(.degrees(rotation))
                    .scaleEffect(scale)
            }
            
            // 提示文字
            if isShaking {
                Text("搖搖搖～")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.teaBrown)
                    .transition(.opacity)
            }
        }
        .onChange(of: isShaking) { _, newValue in
            if newValue {
                startShakeAnimation()
            } else {
                stopShakeAnimation()
            }
        }
    }
    
    private func startShakeAnimation() {
        // 搖晃動畫
        withAnimation(
            .easeInOut(duration: 0.1)
            .repeatForever(autoreverses: true)
        ) {
            rotation = 15
        }
        
        // 縮放動畫
        withAnimation(
            .easeInOut(duration: 0.2)
            .repeatForever(autoreverses: true)
        ) {
            scale = 1.1
        }
    }
    
    private func stopShakeAnimation() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.5)) {
            rotation = 0
            scale = 1.0
        }
    }
}

/// 搖一搖按鈕
struct ShakeButton: View {
    let title: String
    let isLoading: Bool
    let action: () -> Void
    
    init(
        title: String = "幫我選！",
        isLoading: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.isLoading = isLoading
        self.action = action
    }
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            guard !isLoading else { return }
            action()
        }) {
            ZStack {
                // 背景
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        LinearGradient(
                            colors: [.teaBrown, .teaBrown.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: .teaBrown.opacity(0.4), radius: isPressed ? 5 : 15, y: isPressed ? 2 : 8)
                
                // 內容
                HStack(spacing: 12) {
                    if isLoading {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Image(systemName: "dice.fill")
                            .font(.title2)
                    }
                    
                    Text(isLoading ? "搖搖中..." : title)
                        .font(.title3)
                        .fontWeight(.bold)
                }
                .foregroundColor(.white)
            }
            .frame(height: 60)
            .scaleEffect(isPressed ? 0.96 : 1.0)
        }
        .buttonStyle(.plain)
        .disabled(isLoading)
        .onLongPressGesture(minimumDuration: .infinity, pressing: { pressing in
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = pressing
            }
        }, perform: {})
    }
}

#Preview("Shake Animation") {
    @Previewable @State var isShaking = false
    
    VStack {
        ShakeAnimationView(isShaking: $isShaking)
        
        Button("Toggle") {
            isShaking.toggle()
        }
    }
}

#Preview("Shake Button") {
    VStack(spacing: 20) {
        ShakeButton(isLoading: false) {}
        ShakeButton(isLoading: true) {}
    }
    .padding()
}
