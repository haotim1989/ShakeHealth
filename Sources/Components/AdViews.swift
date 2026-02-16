import SwiftUI
import GoogleMobileAds

// MARK: - Banner Ad View

/// 橫幅廣告視圖
/// Pro 用戶自動隱藏廣告
struct BannerAdView: View {
    @EnvironmentObject var userManager: UserManager
    @StateObject private var adManager = AdManager.shared
    @State private var showPaywall = false
    
    var body: some View {
        // Pro 用戶不顯示廣告
        if !userManager.isProUser && adManager.shouldShowAds {
            VStack(spacing: 0) {
                if adManager.isInitialized {
                    BannerViewRepresentable()
                        .frame(height: 50)
                } else {
                    // SDK 尚未初始化，顯示佔位
                    placeholderBanner
                }
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView()
            }
        }
    }
    
    private var placeholderBanner: some View {
        ZStack {
            Rectangle()
                .fill(Color.gray.opacity(0.1))
                .frame(height: 50)
            
            HStack {
                Image(systemName: "megaphone.fill")
                    .foregroundColor(.secondary)
                
                Text("廣告載入中...")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Button {
                    showPaywall = true
                } label: {
                    Text("移除廣告")
                        .font(.caption2)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.teaBrown)
                        .foregroundColor(.white)
                        .clipShape(Capsule())
                }
            }
            .padding(.horizontal)
        }
    }
}

// MARK: - BannerView Representable

/// UIKit BannerView 的 SwiftUI 包裝器
struct BannerViewRepresentable: UIViewRepresentable {
    typealias UIViewType = GoogleMobileAds.BannerView
    
    func makeUIView(context: Context) -> GoogleMobileAds.BannerView {
        let bannerView = GoogleMobileAds.BannerView(adSize: AdSizeBanner)
        bannerView.adUnitID = AdManager.shared.bannerAdUnitID
        bannerView.delegate = context.coordinator
        
        // 設定根視圖控制器
        if let rootVC = UIApplication.shared.rootViewController {
            bannerView.rootViewController = rootVC
        }
        
        // 載入廣告
        let request = GoogleMobileAds.Request()
        bannerView.load(request)
        
        return bannerView
    }
    
    func updateUIView(_ uiView: GoogleMobileAds.BannerView, context: Context) {
        // 不需要更新
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator: NSObject, BannerViewDelegate {
        func bannerViewDidReceiveAd(_ bannerView: GoogleMobileAds.BannerView) {
            print("✅ Banner 廣告載入成功")
        }
        
        func bannerView(_ bannerView: GoogleMobileAds.BannerView, didFailToReceiveAdWithError error: Error) {
            print("❌ Banner 廣告載入失敗: \(error.localizedDescription)")
        }
    }
}

// MARK: - Native Ad View

/// 原生廣告視圖
/// 用於圖鑑列表中每 N 項插入
struct NativeAdCardView: View {
    @EnvironmentObject var userManager: UserManager
    @StateObject private var adLoader = NativeAdLoaderWrapper()
    
    var body: some View {
        // Pro 用戶不顯示廣告
        if !userManager.isProUser {
            if adLoader.nativeAd != nil {
                NativeAdViewRepresentable(nativeAd: adLoader.nativeAd!)
                    .frame(height: 80)
            } else {
                // 廣告載入中或失敗，顯示佔位
                nativeAdPlaceholder
            }
        }
    }
    
    private var nativeAdPlaceholder: some View {
        HStack(spacing: 12) {
            // 廣告圖示
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.gray.opacity(0.1))
                    .frame(width: 50, height: 50)
                
                Image(systemName: "megaphone.fill")
                    .foregroundColor(.secondary)
            }
            
            // 廣告內容
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("贊助內容")
                        .font(.body)
                        .fontWeight(.medium)
                    
                    Text("Ad")
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.yellow.opacity(0.3))
                        .clipShape(Capsule())
                }
                
                Text(adLoader.isLoading ? "載入中..." : "廣告內容")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
        .onAppear {
            adLoader.loadAd()
        }
    }
}

// MARK: - Native Ad Loader Wrapper

/// 原生廣告載入器
@MainActor
class NativeAdLoaderWrapper: NSObject, ObservableObject {
    @Published var nativeAd: GoogleMobileAds.NativeAd?
    @Published var isLoading = false
    
    private var adLoaderInstance: GoogleMobileAds.AdLoader?
    
    func loadAd() {
        guard !isLoading, nativeAd == nil else { return }
        
        isLoading = true
        
        let options = NativeAdMediaAdLoaderOptions()
        options.mediaAspectRatio = .landscape
        
        adLoaderInstance = GoogleMobileAds.AdLoader(
            adUnitID: AdManager.shared.nativeAdUnitID,
            rootViewController: UIApplication.shared.rootViewController,
            adTypes: [.native],
            options: [options]
        )
        adLoaderInstance?.delegate = self
        adLoaderInstance?.load(GoogleMobileAds.Request())
    }
}

extension NativeAdLoaderWrapper: NativeAdLoaderDelegate {
    nonisolated func adLoader(_ adLoader: GoogleMobileAds.AdLoader, didReceive nativeAd: GoogleMobileAds.NativeAd) {
        Task { @MainActor in
            self.nativeAd = nativeAd
            self.isLoading = false
            print("✅ Native 廣告載入成功")
        }
    }
    
    nonisolated func adLoader(_ adLoader: GoogleMobileAds.AdLoader, didFailToReceiveAdWithError error: Error) {
        Task { @MainActor in
            self.isLoading = false
            print("❌ Native 廣告載入失敗: \(error.localizedDescription)")
        }
    }
}

// MARK: - NativeAdView Representable

/// UIKit NativeAdView 的 SwiftUI 包裝器
struct NativeAdViewRepresentable: UIViewRepresentable {
    typealias UIViewType = GoogleMobileAds.NativeAdView
    
    let nativeAd: GoogleMobileAds.NativeAd
    
    func makeUIView(context: Context) -> GoogleMobileAds.NativeAdView {
        let nativeAdView = GoogleMobileAds.NativeAdView()
        
        // 建立並配置子視圖
        let headlineLabel = UILabel()
        headlineLabel.font = .systemFont(ofSize: 14, weight: .medium)
        headlineLabel.text = nativeAd.headline
        nativeAdView.headlineView = headlineLabel
        nativeAdView.addSubview(headlineLabel)
        
        let bodyLabel = UILabel()
        bodyLabel.font = .systemFont(ofSize: 12)
        bodyLabel.textColor = .secondaryLabel
        bodyLabel.text = nativeAd.body
        bodyLabel.numberOfLines = 2
        nativeAdView.bodyView = bodyLabel
        nativeAdView.addSubview(bodyLabel)
        
        // 設定原生廣告
        nativeAdView.nativeAd = nativeAd
        
        // 簡易佈局
        headlineLabel.translatesAutoresizingMaskIntoConstraints = false
        bodyLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            headlineLabel.topAnchor.constraint(equalTo: nativeAdView.topAnchor, constant: 8),
            headlineLabel.leadingAnchor.constraint(equalTo: nativeAdView.leadingAnchor, constant: 16),
            headlineLabel.trailingAnchor.constraint(equalTo: nativeAdView.trailingAnchor, constant: -16),
            
            bodyLabel.topAnchor.constraint(equalTo: headlineLabel.bottomAnchor, constant: 4),
            bodyLabel.leadingAnchor.constraint(equalTo: nativeAdView.leadingAnchor, constant: 16),
            bodyLabel.trailingAnchor.constraint(equalTo: nativeAdView.trailingAnchor, constant: -16),
        ])
        
        return nativeAdView
    }
    
    func updateUIView(_ uiView: GoogleMobileAds.NativeAdView, context: Context) {
        uiView.nativeAd = nativeAd
        (uiView.headlineView as? UILabel)?.text = nativeAd.headline
        (uiView.bodyView as? UILabel)?.text = nativeAd.body
    }
}

// MARK: - Interstitial Ad Manager

/// 插頁廣告管理器
/// 用於隨機喝功能，每日第 N 次抽獎時展示
@MainActor
final class InterstitialAdManager: NSObject, ObservableObject {
    @Published private(set) var isAdReady = false
    @Published private(set) var isShowingAd = false
    
    private var interstitialAd: InterstitialAd?
    private var onDismissCompletion: (() -> Void)?
    
    override init() {
        super.init()
        Task {
            await loadAd()
        }
    }
    
    /// 預先載入插頁廣告
    func loadAd() async {
        guard Constants.FeatureFlags.interstitialAdsEnabled else { return }
        
        do {
            interstitialAd = try await InterstitialAd.load(
                with: AdManager.shared.interstitialAdUnitID,
                request: Request()
            )
            interstitialAd?.fullScreenContentDelegate = self
            isAdReady = true
            print("✅ Interstitial 廣告載入成功")
        } catch {
            print("❌ Interstitial 廣告載入失敗: \(error.localizedDescription)")
            isAdReady = false
        }
    }
    
    /// 展示插頁廣告
    /// - Parameter completion: 廣告關閉後的回呼
    func showAd(completion: @escaping () -> Void) {
        guard let ad = interstitialAd else {
            // 廣告未就緒，直接執行 completion
            print("⚠️ Interstitial 廣告未就緒，跳過")
            completion()
            return
        }
        
        onDismissCompletion = completion
        isShowingAd = true
        ad.present(from: nil)
    }
}

extension InterstitialAdManager: FullScreenContentDelegate {
    nonisolated func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        Task { @MainActor in
            print("✅ Interstitial 廣告已關閉")
            self.isShowingAd = false
            self.interstitialAd = nil
            self.isAdReady = false
            
            // 執行回呼
            self.onDismissCompletion?()
            self.onDismissCompletion = nil
            
            // 預載下一次廣告
            await self.loadAd()
        }
    }
    
    nonisolated func ad(_ ad: FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        Task { @MainActor in
            print("❌ Interstitial 廣告展示失敗: \(error.localizedDescription)")
            self.isShowingAd = false
            self.interstitialAd = nil
            self.isAdReady = false
            
            // 廣告失敗也要執行回呼
            self.onDismissCompletion?()
            self.onDismissCompletion = nil
            
            await self.loadAd()
        }
    }
    
    nonisolated func adWillPresentFullScreenContent(_ ad: FullScreenPresentingAd) {
        print("📱 Interstitial 廣告即將展示")
    }
}

// MARK: - Backward Compatibility Alias
// 保持舊名稱的相容性
typealias NativeAdView = NativeAdCardView

// MARK: - Preview

#Preview {
    VStack {
        NativeAdCardView()
            .padding()
        
        Spacer()
        
        BannerAdView()
    }
    .environmentObject(UserManager.shared)
}
