import SwiftUI
import SwiftData
import StoreKit

/// 設定頁面
struct SettingsView: View {
    @EnvironmentObject var userManager: UserManager
    @EnvironmentObject var appState: AppState
    @Environment(\.modelContext) private var modelContext
    @Environment(\.requestReview) private var requestReview
    
    @State private var showPaywall = false
    @State private var showExportSheet = false
    @State private var showImportPicker = false
    @State private var showImportSuccess = false
    @State private var showImportError = false
    @State private var importedCount = 0
    @State private var errorMessage = ""
    @State private var isRestoring = false
    @State private var showRestoreSuccess = false
    @State private var showRestoreError = false
    
    @Query private var logs: [DrinkLog]
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 自訂標題
                HStack(spacing: 8) {
                    Text("設定")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.teaBrown)
                    
                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
                .padding(.bottom, 8)
                .background(Color.backgroundPrimary)
                
                List {
                // MARK: - 訂閱區塊
                subscriptionSection
                
                // MARK: - 資料備份
                dataBackupSection
                
                // MARK: - 支持我們
                supportSection
                
                // MARK: - 訂閱管理
                subscriptionManagementSection
                
                // MARK: - 關於
                aboutSection
                
                // MARK: - 法律資訊
                legalInfoSection
            }
            .listStyle(.insetGrouped)
            .background(Color.backgroundPrimary)
            .scrollContentBackground(.hidden)
            .toolbar(.hidden, for: .navigationBar)
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView()
                    .environmentObject(userManager)
            }
            .fileImporter(
                isPresented: $showImportPicker,
                allowedContentTypes: [.commaSeparatedText],
                allowsMultipleSelection: false
            ) { result in
                handleImport(result)
            }
            .alert("匯入成功", isPresented: $showImportSuccess) {
                Button("確定", role: .cancel) {}
            } message: {
                Text("已成功匯入 \(importedCount) 筆日記紀錄")
            }
            .alert("匯入失敗", isPresented: $showImportError) {
                Button("確定", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
            .alert("恢復成功", isPresented: $showRestoreSuccess) {
                Button("確定", role: .cancel) {}
            } message: {
                Text("已成功恢復您的購買紀錄。")
            }
            .alert("恢復失敗", isPresented: $showRestoreError) {
                Button("確定", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    // MARK: - 訂閱區塊
    
    // MARK: - 訂閱區塊
    
    private var subscriptionSection: some View {
        Section {
            if userManager.isProUser {
                subscriptionCardContent
            } else {
                Button {
                    showPaywall = true
                } label: {
                    subscriptionCardContent
                }
                .buttonStyle(.plain)
            }
        } header: {
            Text("訂閱")
        }
    }
    
    private var subscriptionCardContent: some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(LinearGradient(
                        colors: [.yellow, .orange],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 44, height: 44)
                
                Image(systemName: "crown.fill")
                    .font(.title2)
                    .foregroundColor(.white)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(userManager.isProUser ? "Premium 會員" : "升級 Premium")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(userManager.isProUser ? "感謝您的支持！" : "解鎖所有進階功能")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if !userManager.isProUser {
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
    }
    
    // MARK: - 資料備份
    
    private var dataBackupSection: some View {
        Section {
            // 匯出 CSV
            Button {
                if userManager.isProUser {
                    exportData()
                } else {
                    showPaywall = true
                }
            } label: {
                HStack {
                    Label("匯出日記", systemImage: "square.and.arrow.up")
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    if !userManager.isProUser {
                        ProBadge()
                    }
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            
            // 匯入 CSV
            Button {
                if userManager.isProUser {
                    showImportPicker = true
                } else {
                    showPaywall = true
                }
            } label: {
                HStack {
                    Label("匯入日記", systemImage: "square.and.arrow.down")
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    if !userManager.isProUser {
                        ProBadge()
                    }
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        } header: {
            Text("資料備份")
        } footer: {
            Text("匯出 CSV 檔案以備份您的日記紀錄，可隨時匯入還原。")
        }
    }
    
    // MARK: - 支持我們
    
    private var supportSection: some View {
        Section {
            // 分享給朋友
            Button {
                ShareService.shareApp()
            } label: {
                HStack {
                    Label("分享給朋友", systemImage: "square.and.arrow.up")
                        .foregroundColor(.primary)
                    Spacer()
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            
            // 撰寫評論
            Button {
                if let url = URL(string: "https://apps.apple.com/app/\(Constants.AppStore.appId)?action=write-review") {
                    UIApplication.shared.open(url)
                }
            } label: {
                HStack {
                    Label("撰寫評論", systemImage: "star.fill")
                        .foregroundColor(.primary)
                    Spacer()
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        } header: {
            Text("支持我們")
        }
    }
    
    // MARK: - 關於
    
    private var aboutSection: some View {
        Section {
            HStack {
                Text("版本")
                Spacer()
                Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
                    .foregroundColor(.secondary)
            }
        } header: {
            Text("關於")
        }
    }
    
    // MARK: - 訂閱管理
    
    private var subscriptionManagementSection: some View {
        Section {
            // 恢復購買
            Button {
                Task { await restorePurchases() }
            } label: {
                HStack {
                    Label("恢復購買", systemImage: "arrow.clockwise")
                        .foregroundColor(.primary)
                    Spacer()
                    if isRestoring {
                        ProgressView()
                            .controlSize(.small)
                    }
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .disabled(isRestoring)
            
            // 管理訂閱
            Button {
                if let url = URL(string: Constants.AppStore.manageSubscriptionURL) {
                    UIApplication.shared.open(url)
                }
            } label: {
                HStack {
                    Label("管理訂閱", systemImage: "creditcard")
                        .foregroundColor(.primary)
                    Spacer()
                    Image(systemName: "arrow.up.right.square")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        } header: {
            Text("訂閱管理")
        }
    }
    
    // MARK: - 法律資訊
    
    private var legalInfoSection: some View {
        Section {
            // 隱私權政策
            Button {
                if let url = URL(string: Constants.Legal.privacyPolicyURL) {
                    UIApplication.shared.open(url)
                }
            } label: {
                HStack {
                    Label("隱私權政策", systemImage: "hand.raised.fill")
                        .foregroundColor(.primary)
                    Spacer()
                    Image(systemName: "arrow.up.right.square")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            
            // 服務條款
            Button {
                if let url = URL(string: Constants.Legal.termsOfServiceURL) {
                    UIApplication.shared.open(url)
                }
            } label: {
                HStack {
                    Label("服務條款", systemImage: "doc.text")
                        .foregroundColor(.primary)
                    Spacer()
                    Image(systemName: "arrow.up.right.square")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        } header: {
            Text("法律資訊")
        }
    }
    

    
    // MARK: - Actions
    
    private func exportData() {
        guard let url = CSVExportService.shared.getExportFileURL(logs: logs) else {
            return
        }
        
        let activityVC = UIActivityViewController(
            activityItems: [url],
            applicationActivities: nil
        )
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            rootVC.present(activityVC, animated: true)
        }
    }
    
    private func handleImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            
            // 取得檔案存取權限
            guard url.startAccessingSecurityScopedResource() else { return }
            defer { url.stopAccessingSecurityScopedResource() }
            
            do {
                importedCount = try CSVExportService.shared.importFromCSV(
                    url: url,
                    userId: appState.userId,
                    context: modelContext
                )
                showImportSuccess = true
                HapticManager.shared.success()
            } catch {
                errorMessage = error.localizedDescription
                showImportError = true
                HapticManager.shared.error()
            }
            
        case .failure(let error):
            errorMessage = error.localizedDescription
            showImportError = true
        }
    }
    
    private func restorePurchases() async {
        isRestoring = true
        defer { isRestoring = false }
        
        do {
            _ = try await SubscriptionService.shared.restorePurchases()
            HapticManager.shared.success()
            showRestoreSuccess = true
        } catch {
            errorMessage = error.localizedDescription
            HapticManager.shared.error()
            showRestoreError = true
        }
    }
}

// MARK: - Pro Badge

private struct ProBadge: View {
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "lock.fill")
                .font(.caption2)
            Text("Premium")
                .font(.caption)
        }
        .foregroundColor(.orange)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.orange.opacity(0.15))
        .clipShape(Capsule())
    }
}

#Preview {
    SettingsView()
        .environmentObject(UserManager.shared)
        .environmentObject(AppState())
}
