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
    @State private var showShareSheet = false
    @State private var showImportSuccess = false
    @State private var showImportError = false
    @State private var importedCount = 0
    @State private var errorMessage = ""
    
    @Query private var logs: [DrinkLog]
    
    var body: some View {
        NavigationStack {
            List {
                // MARK: - 訂閱區塊
                subscriptionSection
                
                // MARK: - 資料備份
                dataBackupSection
                
                // MARK: - 支持我們
                supportSection
                
                // MARK: - 關於
                aboutSection
            }
            .listStyle(.insetGrouped)
            .background(Color.backgroundPrimary)
            .scrollContentBackground(.hidden)
            .navigationTitle("設定")
            .sheet(isPresented: $showPaywall) {
                PaywallView()
                    .environmentObject(userManager)
            }
            .sheet(isPresented: $showShareSheet) {
                shareSheet
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
        }
    }
    
    // MARK: - 訂閱區塊
    
    private var subscriptionSection: some View {
        Section {
            Button {
                showPaywall = true
            } label: {
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
            }
            .buttonStyle(.plain)
        } header: {
            Text("訂閱")
        }
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
                showShareSheet = true
            } label: {
                Label("分享給朋友", systemImage: "square.and.arrow.up")
                    .foregroundColor(.primary)
            }
            .buttonStyle(.plain)
            
            // 撰寫評論
            Button {
                requestReview()
            } label: {
                Label("撰寫評論", systemImage: "star.fill")
                    .foregroundColor(.primary)
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
    
    // MARK: - 分享 Sheet
    
    private var shareSheet: some View {
        let shareText = """
        🧋 飲料日記 - 記錄你的飲料生活
        
        追蹤每日飲料攝取、熱量與咖啡因，讓你喝得更健康！
        
        📲 立即下載：https://apps.apple.com/app/id123456789
        """
        
        return ShareLink(item: shareText) {
            VStack(spacing: 20) {
                Image(systemName: "cup.and.saucer.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.teaBrown)
                
                Text("分享給朋友")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("邀請朋友一起記錄飲料生活！")
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.backgroundPrimary)
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
