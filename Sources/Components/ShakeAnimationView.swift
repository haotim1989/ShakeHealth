import SwiftUI

/// 搖動動畫視圖
struct ShakeAnimationView: View {
    @Binding var isShaking: Bool
    
    private let categories: [DrinkCategory] = DrinkCategory.allCases.filter { $0 != .custom }
    @State private var spinAngle: Double = 0
    @State private var rotation: Double = 0
    @State private var yOffset: CGFloat = 0
    
    var body: some View {
        VStack(spacing: 32) {
            // 快速旋轉的分類圖示
            ZStack {
                // 柔和陰影底座
                Ellipse()
                    .fill(Color.black.opacity(0.08))
                    .frame(width: 100, height: 20)
                    .offset(y: 50)
                    .blur(radius: isShaking ? 6 : 4)
                    .scaleEffect(isShaking ? 0.9 : 1.0)
                
                // 中央底座
                ZStack {
                    Circle()
                        .fill(Color.milkCream.opacity(0.6))
                        .frame(width: 60, height: 60)
                    
                    Text("?")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.teaBrown.opacity(0.6))
                }
                .rotationEffect(.degrees(rotation))
                .offset(y: yOffset)
                
                // 6 個分類圖示快速旋轉
                ForEach(Array(categories.enumerated()), id: \.element.id) { index, category in
                    let baseAngle = Double(index) * (360.0 / Double(categories.count))
                    let currentAngle = baseAngle + spinAngle
                    let radian = currentAngle * .pi / 180
                    let orbitR: CGFloat = 50
                    
                    let x = orbitR * CGFloat(cos(radian))
                    let y = orbitR * CGFloat(sin(radian))
                    
                    ZStack {
                        Circle()
                            .fill(category.themeColor.opacity(0.2))
                            .frame(width: 32, height: 32)
                        
                        CategoryIconView(category: category, size: 18)
                    }
                    .offset(x: x, y: y)
                    .rotationEffect(.degrees(rotation))
                    .offset(y: yOffset)
                    .zIndex(Double(sin(radian)))
                }
            }
            .frame(height: 140)
            
            // 載入指示器
            if isShaking {
                VStack(spacing: 16) {
                    // 三個跳動的點
                    HStack(spacing: 8) {
                        ForEach(0..<3, id: \.self) { index in
                            Circle()
                                .fill(Color.teaBrown)
                                .frame(width: 10, height: 10)
                                .offset(y: isShaking ? -8 : 0)
                                .animation(
                                    .easeInOut(duration: 0.4)
                                    .repeatForever()
                                    .delay(Double(index) * 0.15),
                                    value: isShaking
                                )
                        }
                    }
                    
                    Text("選飲料中...")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                }
            }
        }
        .onChange(of: isShaking) { _, newValue in
            if newValue {
                startShakeAnimation()
            } else {
                stopShakeAnimation()
            }
        }
        .onAppear {
            if isShaking {
                startShakeAnimation()
            }
        }
    }
    
    private func startShakeAnimation() {
        // 左右搖晃
        withAnimation(
            .easeInOut(duration: 0.1)
            .repeatForever(autoreverses: true)
        ) {
            rotation = 8
        }
        
        // 上下彈跳
        withAnimation(
            .easeInOut(duration: 0.25)
            .repeatForever(autoreverses: true)
        ) {
            yOffset = -12
        }
        
        // 圖示快速旋轉（扭蛋翻滾感）
        withAnimation(
            .linear(duration: 1.0)
            .repeatForever(autoreverses: false)
        ) {
            spinAngle = 360
        }
    }
    
    private func stopShakeAnimation() {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
            rotation = 0
            yOffset = 0
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
