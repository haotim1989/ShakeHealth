import SwiftUI

/// 首次啟動產品導覽
struct OnboardingView: View {
    @Binding var isPresented: Bool
    @State private var currentPage = 0
    
    private let pages: [OnboardingPage] = [
        OnboardingPage(
            icon: "dice.fill",
            iconColor: .teaBrown,
            title: "隨機喝",
            subtitle: "今天喝什麼？讓我幫你決定！",
            description: "設定偏好條件（品牌、分類、甜度、咖啡因等），我們會從圖鑑中隨機挑一杯。還有智慧推薦和避雷模式幫你選出最對味的飲料！",
            categories: [.milkTea, .pureTea, .fruitTea, .coffee, .fresh, .special]
        ),
        OnboardingPage(
            icon: "magnifyingglass",
            iconColor: .fruitOrange,
            title: "找熱量",
            subtitle: "喝之前，先看看熱量和糖分",
            description: "收錄超過千款手搖飲資料，支援品牌搜尋與分類瀏覽。每杯飲料都標示熱量、糖分與咖啡因，幫你喝得更安心。",
            categories: []
        ),
        OnboardingPage(
            icon: "book.fill",
            iconColor: .greenTea,
            title: "我的日記",
            subtitle: "記錄每一杯，回顧你的飲品旅程",
            description: "輕鬆記錄每天喝了什麼、甜度冰塊怎麼選、評分幾顆星。還能自訂飲料，查看每日/每週的飲用統計。",
            categories: []
        ),
    ]
    
    var body: some View {
        ZStack {
            // 背景
            Color.backgroundPrimary
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // 跳過按鈕
                HStack {
                    Spacer()
                    if currentPage < pages.count - 1 {
                        Button("跳過") {
                            completeOnboarding()
                        }
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 8)
                .frame(height: 44)
                
                // 頁面內容
                TabView(selection: $currentPage) {
                    ForEach(Array(pages.enumerated()), id: \.offset) { index, page in
                        OnboardingPageView(page: page)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut(duration: 0.3), value: currentPage)
                
                // 底部：頁面指示器 + 按鈕
                VStack(spacing: 24) {
                    // 頁面指示器
                    HStack(spacing: 8) {
                        ForEach(0..<pages.count, id: \.self) { index in
                            Capsule()
                                .fill(index == currentPage ? Color.teaBrown : Color.teaBrown.opacity(0.2))
                                .frame(width: index == currentPage ? 24 : 8, height: 8)
                                .animation(.spring(response: 0.3), value: currentPage)
                        }
                    }
                    
                    // 下一步 / 開始使用
                    Button {
                        if currentPage < pages.count - 1 {
                            withAnimation {
                                currentPage += 1
                            }
                        } else {
                            completeOnboarding()
                        }
                    } label: {
                        Text(currentPage < pages.count - 1 ? "下一步" : "開始使用 🎉")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.teaBrown)
                            )
                            .shadow(color: .teaBrown.opacity(0.3), radius: 8, y: 4)
                    }
                    .padding(.horizontal, 24)
                }
                .padding(.bottom, 40)
            }
        }
    }
    
    private func completeOnboarding() {
        UserDefaults.standard.set(true, forKey: Constants.StorageKeys.onboardingCompleted)
        withAnimation(.easeOut(duration: 0.3)) {
            isPresented = false
        }
    }
}

// MARK: - Data Model

struct OnboardingPage {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    let description: String
    let categories: [DrinkCategory]
}

// MARK: - Page View

struct OnboardingPageView: View {
    let page: OnboardingPage
    @State private var isAppeared = false
    
    var body: some View {
        VStack(spacing: 28) {
            Spacer()
            
            // 圖示區
            ZStack {
                // 外圈光暈
                Circle()
                    .fill(page.iconColor.opacity(0.08))
                    .frame(width: 180, height: 180)
                    .scaleEffect(isAppeared ? 1.0 : 0.6)
                
                // 內圈
                Circle()
                    .fill(page.iconColor.opacity(0.15))
                    .frame(width: 130, height: 130)
                    .scaleEffect(isAppeared ? 1.0 : 0.7)
                
                // 圖示
                if !page.categories.isEmpty {
                    // 隨機喝：顯示 6 個分類圖示軌道
                    OnboardingGashaponView(categories: page.categories)
                        .scaleEffect(isAppeared ? 1.0 : 0.5)
                } else {
                    Image(systemName: page.icon)
                        .font(.system(size: 56))
                        .foregroundColor(page.iconColor)
                        .scaleEffect(isAppeared ? 1.0 : 0.5)
                }
            }
            .animation(.spring(response: 0.6, dampingFraction: 0.7), value: isAppeared)
            
            // 文字區
            VStack(spacing: 24) {
                Text(page.title)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.teaBrown)
                
                Text(page.subtitle)
                    .font(.title3)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Text(page.description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 32)
            }
            .opacity(isAppeared ? 1.0 : 0.0)
            .offset(y: isAppeared ? 0 : 20)
            .animation(.easeOut(duration: 0.5).delay(0.2), value: isAppeared)
            
            Spacer()
            Spacer()
        }
        .onAppear {
            isAppeared = true
        }
        .onDisappear {
            isAppeared = false
        }
    }
}

// MARK: - 隨機喝頁面的迷你扭蛋圖示

struct OnboardingGashaponView: View {
    let categories: [DrinkCategory]
    @State private var orbitAngle: Double = 0
    
    var body: some View {
        ZStack {
            // 中央骰子圖示
            Image(systemName: "dice.fill")
                .font(.system(size: 36))
                .foregroundColor(.teaBrown)
            
            // 軌道上的分類圖示
            ForEach(Array(categories.enumerated()), id: \.element.id) { index, category in
                let baseAngle = Double(index) * (360.0 / Double(categories.count))
                let currentAngle = baseAngle + orbitAngle
                let radian = currentAngle * .pi / 180
                let radius: CGFloat = 52
                
                ZStack {
                    Circle()
                        .fill(category.themeColor.opacity(0.2))
                        .frame(width: 30, height: 30)
                    
                    CategoryIconView(category: category, size: 16)
                }
                .offset(
                    x: radius * CGFloat(cos(radian)),
                    y: radius * CGFloat(sin(radian))
                )
                .zIndex(Double(sin(radian)))
            }
        }
        .frame(width: 140, height: 140)
        .onAppear {
            withAnimation(
                .linear(duration: 10)
                .repeatForever(autoreverses: false)
            ) {
                orbitAngle = 360
            }
        }
    }
}

// MARK: - Preview

#Preview {
    OnboardingView(isPresented: .constant(true))
}
