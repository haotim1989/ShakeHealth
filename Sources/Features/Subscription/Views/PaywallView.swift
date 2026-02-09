import SwiftUI
import RevenueCat

/// 付費牆視圖
/// 展示訂閱方案並處理購買流程
struct PaywallView: View {
    @EnvironmentObject var userManager: UserManager
    @StateObject private var subscriptionService = SubscriptionService.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedPackage: Package?
    @State private var isPurchasing = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.backgroundPrimary
                    .ignoresSafeArea()
                
                if subscriptionService.isLoading && subscriptionService.offerings == nil {
                    // 載入中
                    loadingView
                } else if let offerings = subscriptionService.offerings,
                          let currentOffering = offerings.current {
                    // 顯示方案
                    ScrollView {
                        VStack(spacing: 24) {
                            headerSection
                            featuresSection
                            packagesSection(packages: currentOffering.availablePackages)
                            purchaseButton
                            legalSection
                        }
                        .padding()
                    }
                } else {
                    // 無法載入或測試模式，使用本地方案
                    ScrollView {
                        VStack(spacing: 24) {
                            headerSection
                            featuresSection
                            fallbackPackagesSection
                            fallbackPurchaseButton
                            legalSection
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("升級 Premium")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("關閉") {
                        dismiss()
                    }
                }
            }
        }
        .alert("購買失敗", isPresented: $showError) {
            Button("確定", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
        .task {
            // 載入 Offerings
            if subscriptionService.offerings == nil {
                await subscriptionService.fetchOfferings()
            }
            // 預選年訂閱
            if let yearly = subscriptionService.offerings?.current?.annual {
                selectedPackage = yearly
            } else if let firstPackage = subscriptionService.offerings?.current?.availablePackages.first {
                selectedPackage = firstPackage
            }
        }
    }
    
    // MARK: - Loading View
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            Text("載入訂閱方案...")
                .foregroundColor(.secondary)
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "crown.fill")
                .font(.system(size: 60))
                .foregroundColor(.yellow)
            
            Text("飲料日記 Premium")
                .font(.title)
                .fontWeight(.bold)
            
            Text("解鎖所有進階功能")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.top, 20)
    }
    
    // MARK: - Features Section
    
    private var featuresSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("包含功能")
                .font(.headline)
            
            FeatureRow(icon: "sparkles", title: "智慧推薦", description: "優先顯示你喜歡的飲料")
            FeatureRow(icon: "hand.thumbsdown.fill", title: "避雷模式", description: "自動排除低評價飲料")
            FeatureRow(icon: "square.and.pencil", title: "自訂飲料", description: "新增圖鑑沒有的飲料")
            FeatureRow(icon: "doc.text.magnifyingglass", title: "月報表", description: "完整健康數據分析")
            FeatureRow(icon: "arrow.up.arrow.down.circle.fill", title: "資料備份", description: "匯出匯入 CSV 檔案")
            FeatureRow(icon: "xmark.circle.fill", title: "無廣告", description: "純淨使用體驗")
        }
        .padding()
        .background(Color.milkCream.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    // MARK: - Packages Section (RevenueCat)
    
    private func packagesSection(packages: [Package]) -> some View {
        VStack(spacing: 12) {
            ForEach(packages, id: \.identifier) { package in
                RevenueCatPackageCard(
                    package: package,
                    isSelected: selectedPackage?.identifier == package.identifier,
                    onTap: { selectedPackage = package }
                )
            }
        }
    }
    
    // MARK: - Purchase Button (RevenueCat)
    
    private var purchaseButton: some View {
        VStack(spacing: 12) {
            Button {
                Task { await purchase() }
            } label: {
                HStack {
                    if isPurchasing {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text("繼續")
                            .fontWeight(.semibold)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.teaBrown)
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .disabled(isPurchasing || selectedPackage == nil)
            
            Button("恢復購買") {
                Task { await restore() }
            }
            .font(.footnote)
            .foregroundColor(.secondary)
        }
    }
    
    // MARK: - Fallback Packages Section (Local)
    
    @State private var selectedLocalPackage: SubscriptionPackage = .yearly
    
    private var fallbackPackagesSection: some View {
        VStack(spacing: 12) {
            ForEach(SubscriptionPackage.allCases) { package in
                PackageCard(
                    package: package,
                    isSelected: selectedLocalPackage == package,
                    onTap: { selectedLocalPackage = package }
                )
            }
        }
    }
    
    // MARK: - Fallback Purchase Button (Test Mode)
    
    private var fallbackPurchaseButton: some View {
        VStack(spacing: 12) {
            Button {
                Task { await fallbackPurchase() }
            } label: {
                HStack {
                    if isPurchasing {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text("繼續 (測試模式)")
                            .fontWeight(.semibold)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.teaBrown)
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .disabled(isPurchasing)
            
            Text("⚠️ 測試模式：RevenueCat 未連接")
                .font(.caption)
                .foregroundColor(.orange)
        }
    }
    
    // MARK: - Legal Section
    
    private var legalSection: some View {
        VStack(spacing: 8) {
            if let package = selectedPackage {
                Text("訂閱將自動續訂，可隨時在設定中取消。訂閱後將收取 \(package.localizedPriceString)。")
            } else {
                Text("訂閱將自動續訂，可隨時在設定中取消。")
            }
        }
        .font(.caption2)
        .foregroundColor(.secondary)
        .multilineTextAlignment(.center)
        .padding(.horizontal)
    }
    
    // MARK: - Actions
    
    private func purchase() async {
        guard let package = selectedPackage else { return }
        
        isPurchasing = true
        defer { isPurchasing = false }
        
        do {
            _ = try await subscriptionService.purchase(package: package)
            HapticManager.shared.success()
            dismiss()
        } catch SubscriptionError.userCancelled {
            // 使用者取消，不顯示錯誤
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
    
    private func restore() async {
        isPurchasing = true
        defer { isPurchasing = false }
        
        do {
            _ = try await subscriptionService.restorePurchases()
            HapticManager.shared.success()
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
    
    private func fallbackPurchase() async {
        isPurchasing = true
        defer { isPurchasing = false }
        
        let success = await subscriptionService.simulatePurchaseForTesting()
        
        if success {
            HapticManager.shared.success()
            dismiss()
        } else {
            errorMessage = "模擬購買失敗"
            showError = true
        }
    }
}

// MARK: - Feature Row

private struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.teaBrown)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "checkmark")
                .foregroundColor(.green)
        }
    }
}

// MARK: - RevenueCat Package Card

private struct RevenueCatPackageCard: View {
    let package: Package
    let isSelected: Bool
    let onTap: () -> Void
    
    private var isYearly: Bool {
        package.packageType == .annual
    }
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(package.storeProduct.localizedTitle)
                            .font(.headline)
                        
                        if isYearly {
                            Text("最超值")
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Color.green.opacity(0.2))
                                .foregroundColor(.green)
                                .clipShape(Capsule())
                        }
                    }
                    
                    Text(package.storeProduct.localizedDescription)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text(package.localizedPriceString)
                        .font(.title3)
                        .fontWeight(.bold)
                    
                    if isYearly, let monthlyPrice = calculateMonthlyPrice() {
                        Text("\(monthlyPrice)/月")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding()
            .background(isSelected ? Color.teaBrown.opacity(0.1) : Color.gray.opacity(0.05))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.teaBrown : Color.gray.opacity(0.3), lineWidth: isSelected ? 2 : 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
    
    private func calculateMonthlyPrice() -> String? {
        let price = package.storeProduct.price as Decimal
        let monthlyPrice = price / 12
        
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale.current
        
        return formatter.string(from: monthlyPrice as NSDecimalNumber)
    }
}

// MARK: - Local Package Card (Fallback)

private struct PackageCard: View {
    let package: SubscriptionPackage
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(package.rawValue)
                            .font(.headline)
                        
                        if let savings = package.savings {
                            Text(savings)
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Color.green.opacity(0.2))
                                .foregroundColor(.green)
                                .clipShape(Capsule())
                        }
                    }
                    
                    Text(package.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text(package.price)
                        .font(.title3)
                        .fontWeight(.bold)
                    
                    Text(package.pricePerMonth)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(isSelected ? Color.teaBrown.opacity(0.1) : Color.gray.opacity(0.05))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.teaBrown : Color.gray.opacity(0.3), lineWidth: isSelected ? 2 : 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    PaywallView()
        .environmentObject(UserManager.shared)
}
