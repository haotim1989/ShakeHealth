import SwiftUI

/// 付費牆視圖
/// 展示訂閱方案並處理購買流程
struct PaywallView: View {
    @EnvironmentObject var userManager: UserManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedPackage: SubscriptionPackage = .yearly
    @State private var isPurchasing = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    headerSection
                    
                    // Features
                    featuresSection
                    
                    // Packages
                    packagesSection
                    
                    // Purchase Button
                    purchaseButton
                    
                    // Legal
                    legalSection
                }
                .padding()
            }
            .background(Color.backgroundPrimary)
            .navigationTitle("升級 Pro")
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
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "crown.fill")
                .font(.system(size: 60))
                .foregroundColor(.yellow)
            
            Text("ShakeHealth Pro")
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
            FeatureRow(icon: "doc.text.magnifyingglass", title: "月報表", description: "完整健康數據分析")
            FeatureRow(icon: "infinity", title: "無限日記", description: "每日無筆數限制")
            FeatureRow(icon: "xmark.circle.fill", title: "無廣告", description: "純淨使用體驗")
        }
        .padding()
        .background(Color.milkCream.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    // MARK: - Packages Section
    
    private var packagesSection: some View {
        VStack(spacing: 12) {
            ForEach(SubscriptionPackage.allCases) { package in
                PackageCard(
                    package: package,
                    isSelected: selectedPackage == package,
                    onTap: { selectedPackage = package }
                )
            }
        }
    }
    
    // MARK: - Purchase Button
    
    private var purchaseButton: some View {
        VStack(spacing: 12) {
            Button {
                Task {
                    await purchase()
                }
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
            .disabled(isPurchasing)
            
            Button("恢復購買") {
                Task {
                    await restore()
                }
            }
            .font(.footnote)
            .foregroundColor(.secondary)
        }
    }
    
    // MARK: - Legal Section
    
    private var legalSection: some View {
        Text("訂閱將自動續訂，可隨時在設定中取消。訂閱後將收取 \(selectedPackage.price)。")
            .font(.caption2)
            .foregroundColor(.secondary)
            .multilineTextAlignment(.center)
            .padding(.horizontal)
    }
    
    // MARK: - Actions
    
    private func purchase() async {
        isPurchasing = true
        
        let success = await userManager.purchaseSubscription(package: selectedPackage)
        
        isPurchasing = false
        
        if success {
            HapticManager.shared.success()
            dismiss()
        } else {
            errorMessage = "購買過程中發生錯誤，請稍後再試。"
            showError = true
        }
    }
    
    private func restore() async {
        isPurchasing = true
        
        let success = await userManager.restorePurchases()
        
        isPurchasing = false
        
        if success {
            HapticManager.shared.success()
            dismiss()
        } else {
            errorMessage = "找不到可恢復的購買紀錄。"
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

// MARK: - Package Card

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
