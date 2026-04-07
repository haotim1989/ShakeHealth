import SwiftUI
import SwiftData
import StoreKit
import RevenueCat

/// 設定頁面
struct SettingsView: View {
    @EnvironmentObject var userManager: UserManager
    @EnvironmentObject var appState: AppState
    @Environment(\.modelContext) private var modelContext
    @Environment(\.requestReview) private var requestReview
    
    @State private var showPaywall = false
    @State private var isPurchasing = false
    @State private var showPurchaseError = false
    @State private var showExportSheet = false
    @State private var showImportPicker = false
    @State private var showImportSuccess = false
    @State private var showImportError = false
    @State private var importedCount = 0
    @State private var errorMessage = ""
    @State private var isRestoring = false
    @State private var showRestoreSuccess = false
    @State private var showRestoreError = false
    @State private var showCopiedAlert = false
    
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
                
                // MARK: - 聯絡我們
                contactSection
                
                // MARK: - 法律資訊
                legalInfoSection
            }
            .listStyle(.insetGrouped)
            .background(Color.backgroundPrimary)
            .scrollContentBackground(.hidden)
            .toolbar(.hidden, for: .navigationBar)
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView(source: "settings_list")
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
            .alert("購買失敗", isPresented: $showPurchaseError) {
                Button("確定", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
            .alert("已複製信箱", isPresented: $showCopiedAlert) {
                Button("確定", role: .cancel) {}
            } message: {
                Text("此設備似乎未設定郵件 App，我們已將客服信箱 ( \(Constants.Legal.supportEmail) ) 複製到您的剪貼簿中。")
            }
        }
    }
    
    // MARK: - 訂閱區塊
    
    // MARK: - 訂閱區塊
    
    private var subscriptionSection: some View {
        Group {
            if userManager.isProUser {
                // 原有的 Pro 會員設計不變，直接放進 Section
                Section {
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
                            Text("Premium 會員")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            Text("感謝您的支持！")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("訂閱")
                }
            } else {
                // 非 Pro 用戶的全新圖文促銷卡片 (符合飲料日記設計規範)
                Section {
                    VStack(alignment: .trailing, spacing: 12) {
                        // 卡片本體
                        Button {
                            Task { await purchaseAnnualPlan() }
                        } label: {
                            HStack(alignment: .center) {
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack(spacing: 4) {
                                        Image(systemName: "sparkles")
                                            .foregroundColor(.teaBrown.opacity(0.8))
                                            .font(.caption)
                                        Text("恭喜獲得試用機會")
                                            .font(.footnote)
                                            .fontWeight(.bold)
                                            .foregroundColor(.primary.opacity(0.8))
                                        Image(systemName: "sparkles")
                                            .foregroundColor(.teaBrown.opacity(0.8))
                                            .font(.caption)
                                    }
                                    
                                    HStack(spacing: 2) {
                                        Text("7")
                                            .font(.system(size: 26, weight: .black, design: .rounded))
                                            .foregroundColor(.teaBrown)
                                        Text(" 天免費試用")
                                            .font(.system(size: 20, weight: .bold))
                                            .foregroundStyle(LinearGradient(colors: [Color(red: 0.6, green: 0.5, blue: 0.4), Color.orange.opacity(0.8)], startPoint: .leading, endPoint: .trailing))
                                    }
                                    
                                    HStack(spacing: 4) {
                                        Text("飲料日記")
                                            .font(.headline)
                                            .fontWeight(.heavy)
                                            .foregroundColor(.primary)
                                        Text("Premium")
                                            .font(.headline)
                                            .fontWeight(.heavy)
                                            .foregroundColor(.teaBrown)
                                    }
                                    
                                    Text("之後 $390/年，可隨時取消")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                if isPurchasing {
                                    ProgressView()
                                        .tint(.white)
                                        .padding(.horizontal, 30)
                                        .padding(.vertical, 12)
                                        .background(Color.teaBrown)
                                        .clipShape(Capsule())
                                } else {
                                    Text("領取試用")
                                        .font(.subheadline)
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 18)
                                        .padding(.vertical, 12)
                                        .background(Color.teaBrown)
                                        .clipShape(Capsule())
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 24)
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 24))
                            .shadow(color: .black.opacity(0.04), radius: 10, y: 4)
                        }
                        .buttonStyle(.plain)
                        .disabled(isPurchasing)
                        
                        // 底部文字
                        Button {
                            showPaywall = true
                        } label: {
                            HStack(spacing: 4) {
                                Text("查看所有訂閱方案")
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 10, weight: .bold))
                            }
                            .font(.footnote)
                            .fontWeight(.medium)
                            .foregroundColor(.teaBrown.opacity(0.8))
                        }
                        .padding(.trailing, 8)
                        .padding(.bottom, 8)
                    }
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets(top: 16, leading: 0, bottom: 4, trailing: 0))
                }
            }
        }
    }
    
    private func purchaseAnnualPlan() async {
        guard !isPurchasing else { return }
        isPurchasing = true
        defer { isPurchasing = false }
        
        let service = SubscriptionService.shared
        if let packages = service.offerings?.current?.availablePackages {
            // 嘗試取得年度方案 ($rc_annual) 或 fallback 到第一個方案
            let targetPackage = packages.first { $0.packageType == .annual } ?? packages.first
            
            if let targetPackage = targetPackage {
                // 記錄開始購買直購方案
                AnalyticsService.shared.logEvent(.paywallPurchaseStart, parameters: [
                    AnalyticsService.ParamKey.source: "settings_promo_banner",
                    AnalyticsService.ParamKey.packageType: targetPackage.identifier
                ])
                
                do {
                    _ = try await service.purchase(package: targetPackage)
                    
                    // 記錄購買成功
                    AnalyticsService.shared.logEvent(.paywallPurchaseSuccess, parameters: [
                        AnalyticsService.ParamKey.source: "settings_promo_banner",
                        AnalyticsService.ParamKey.packageType: targetPackage.identifier
                    ])
                    
                    // 成功購買後狀態會由 SubscriptionService 透過 Combine 廣播給 UserManager
                } catch SubscriptionError.userCancelled {
                    // 若是被使用者取消
                    AnalyticsService.shared.logEvent(.paywallPurchaseCancel, parameters: [
                        AnalyticsService.ParamKey.source: "settings_promo_banner",
                        AnalyticsService.ParamKey.packageType: targetPackage.identifier
                    ])
                } catch {
                    // 真的錯誤
                    AnalyticsService.shared.logEvent(.paywallPurchaseError, parameters: [
                        AnalyticsService.ParamKey.source: "settings_promo_banner",
                        AnalyticsService.ParamKey.packageType: targetPackage.identifier,
                        "error": error.localizedDescription
                    ])
                    errorMessage = error.localizedDescription
                    showPurchaseError = true
                }
            } else {
                // 如果抓不到 package，退回顯示 Paywall
                showPaywall = true
            }
        } else {
            showPaywall = true
        }
    }
    
    // MARK: - 資料備份
    
    private var dataBackupSection: some View {
        Section {
            // iCloud 同步狀態 (僅展示，由無感觸發)
            HStack {
                Label("iCloud 自動同步", systemImage: "cloud.fill")
                    .foregroundColor(.primary)
                
                Spacer()
                
                if userManager.isProUser {
                    Text("已啟用")
                        .font(.caption)
                        .foregroundColor(.green)
                } else {
                    ProBadge()
                }
            }
            .contentShape(Rectangle())
            .onTapGesture {
                if !userManager.isProUser {
                    showPaywall = true
                }
            }
            
            // 匯出 CSV
            Button {
                if userManager.isProUser {
                    exportData()
                } else {
                    showPaywall = true
                }
            } label: {
                HStack {
                    Label("匯出試算表 (CSV)", systemImage: "square.and.arrow.up")
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
                    Label("匯入還原 (CSV)", systemImage: "square.and.arrow.down")
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
            Text("資料備份與還原")
        } footer: {
            if userManager.isProUser {
                Text("您的日記將自動透過 iCloud 同步至您的所有設備。您也可以隨時使用 CSV 格式手動匯出及匯入資料。")
            } else {
                Text("升級 Premium 以啟用 iCloud 自動跨裝置無縫同步，以及 CSV 資料匯出功能。")
            }
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
                AnalyticsService.shared.logEvent(.paywallRestoreClick, parameters: [
                    AnalyticsService.ParamKey.source: "settings_list"
                ])
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
        } footer: {
            Text("免責聲明：本 App 提供的營養與熱量數據僅供參考，不構成專業醫療建議。如有健康疑慮，請諮詢專業醫師。")
                .font(.caption2)
                .foregroundColor(.secondary)
                .padding(.top, 4)
        }
    }
    
    // MARK: - 聯絡我們
    
    private var contactSection: some View {
        Section {
            Button {
                if let url = URL(string: "mailto:\(Constants.Legal.supportEmail)") {
                    UIApplication.shared.open(url)
                }
            } label: {
                HStack {
                    Label("聯絡我們", systemImage: "envelope.fill")
                        .foregroundColor(.primary)
                    Spacer()
                    Text(Constants.Legal.supportEmail)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        } header: {
            Text("支援")
        }
    }
    

    
    // MARK: - Actions
    
    private func exportData() {
        AnalyticsService.shared.logEvent(.dataExportCSV, parameters: [
            AnalyticsService.ParamKey.logCount: logs.count
        ])
        
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
        AnalyticsService.shared.logEvent(.paywallRestoreClick, parameters: [
            AnalyticsService.ParamKey.source: "settings"
        ])
        
        isRestoring = true
        defer { isRestoring = false }
        
        // 測試模式防呆處理 (若未連接 RevenueCat 金鑰)
        if !SubscriptionService.shared.isConfigured {
            let success = await SubscriptionService.shared.simulatePurchaseForTesting()
            if success {
                HapticManager.shared.success()
                showRestoreSuccess = true
            } else {
                errorMessage = "模擬恢復失敗"
                HapticManager.shared.error()
                showRestoreError = true
            }
            return
        }
        
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
