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
                    .frame(height: 280)
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
        
        // --- 創建 UI 元素 ---
        
        // 1. Icon View
        let iconView = UIImageView()
        iconView.layer.cornerRadius = 4
        iconView.clipsToBounds = true
        iconView.contentMode = .scaleAspectFill
        nativeAdView.addSubview(iconView)
        nativeAdView.iconView = iconView
        
        // 2. Headline
        let headlineLabel = UILabel()
        headlineLabel.font = .systemFont(ofSize: 16, weight: .bold)
        headlineLabel.numberOfLines = 1
        nativeAdView.addSubview(headlineLabel)
        nativeAdView.headlineView = headlineLabel
        
        // 3. Body
        let bodyLabel = UILabel()
        bodyLabel.font = .systemFont(ofSize: 12)
        bodyLabel.textColor = .secondaryLabel
        bodyLabel.numberOfLines = 2
        nativeAdView.addSubview(bodyLabel)
        nativeAdView.bodyView = bodyLabel
        
        // 4. Media View (AdMob policy requirement)
        let mediaView = GoogleMobileAds.MediaView()
        nativeAdView.addSubview(mediaView)
        nativeAdView.mediaView = mediaView
        
        // 5. Call To Action Button
        let callToActionButton = UIButton(type: .system)
        callToActionButton.backgroundColor = .systemBlue
        callToActionButton.setTitleColor(.white, for: .normal)
        callToActionButton.titleLabel?.font = .systemFont(ofSize: 14, weight: .semibold)
        callToActionButton.layer.cornerRadius = 8
        nativeAdView.addSubview(callToActionButton)
        nativeAdView.callToActionView = callToActionButton
        
        // 6. Ad Attribtion label
        let adLabel = UILabel()
        adLabel.text = "Ad"
        adLabel.font = .systemFont(ofSize: 10, weight: .bold)
        adLabel.textColor = .white
        adLabel.backgroundColor = .systemOrange
        adLabel.layer.cornerRadius = 3
        adLabel.clipsToBounds = true
        adLabel.textAlignment = .center
        nativeAdView.addSubview(adLabel)
        
        // --- 設定約束 (Auto Layout) ---
        iconView.translatesAutoresizingMaskIntoConstraints = false
        headlineLabel.translatesAutoresizingMaskIntoConstraints = false
        bodyLabel.translatesAutoresizingMaskIntoConstraints = false
        mediaView.translatesAutoresizingMaskIntoConstraints = false
        callToActionButton.translatesAutoresizingMaskIntoConstraints = false
        adLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            // Ad Label (Top Left corner of icon)
            adLabel.topAnchor.constraint(equalTo: nativeAdView.topAnchor, constant: 8),
            adLabel.leadingAnchor.constraint(equalTo: nativeAdView.leadingAnchor, constant: 8),
            adLabel.widthAnchor.constraint(equalToConstant: 20),
            adLabel.heightAnchor.constraint(equalToConstant: 14),
            
            // Icon
            iconView.topAnchor.constraint(equalTo: nativeAdView.topAnchor, constant: 12),
            iconView.leadingAnchor.constraint(equalTo: nativeAdView.leadingAnchor, constant: 12),
            iconView.widthAnchor.constraint(equalToConstant: 40),
            iconView.heightAnchor.constraint(equalToConstant: 40),
            
            // Headline
            headlineLabel.topAnchor.constraint(equalTo: iconView.topAnchor),
            headlineLabel.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 8),
            headlineLabel.trailingAnchor.constraint(equalTo: nativeAdView.trailingAnchor, constant: -12),
            
            // Body
            bodyLabel.topAnchor.constraint(equalTo: headlineLabel.bottomAnchor, constant: 4),
            bodyLabel.leadingAnchor.constraint(equalTo: headlineLabel.leadingAnchor),
            bodyLabel.trailingAnchor.constraint(equalTo: headlineLabel.trailingAnchor),
            
            // Media View (Below the top row)
            mediaView.topAnchor.constraint(equalTo: iconView.bottomAnchor, constant: 12),
            mediaView.leadingAnchor.constraint(equalTo: nativeAdView.leadingAnchor, constant: 12),
            mediaView.trailingAnchor.constraint(equalTo: nativeAdView.trailingAnchor, constant: -12),
            mediaView.heightAnchor.constraint(equalToConstant: 150), // Fixed height for media
            
            // Call To Action
            callToActionButton.topAnchor.constraint(equalTo: mediaView.bottomAnchor, constant: 12),
            callToActionButton.trailingAnchor.constraint(equalTo: nativeAdView.trailingAnchor, constant: -12),
            callToActionButton.bottomAnchor.constraint(equalTo: nativeAdView.bottomAnchor, constant: -12),
            callToActionButton.heightAnchor.constraint(equalToConstant: 36),
            callToActionButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 80)
        ])
        
        return nativeAdView
    }
    
    func updateUIView(_ uiView: GoogleMobileAds.NativeAdView, context: Context) {
        uiView.nativeAd = nativeAd
        
        // 填入資料
        (uiView.headlineView as? UILabel)?.text = nativeAd.headline
        (uiView.bodyView as? UILabel)?.text = nativeAd.body
        (uiView.callToActionView as? UIButton)?.setTitle(nativeAd.callToAction, for: .normal)
        
        // Icon
        if let icon = nativeAd.icon?.image {
            (uiView.iconView as? UIImageView)?.image = icon
            uiView.iconView?.isHidden = false
        } else {
            uiView.iconView?.isHidden = true
        }
        
        // Media (AdMob handles this via nativeAd injection, but we make sure it's presented)
        if nativeAd.mediaContent.hasVideoContent {
             uiView.mediaView?.mediaContent = nativeAd.mediaContent
        }
        
        // CTA Visibility
        uiView.callToActionView?.isHidden = nativeAd.callToAction == nil
    }
}

// MARK: - Interstitial Ad Manager

/// 插頁廣告管理器
/// 用於隨機喝功能，每日第 N 次抽獎時展示
@MainActor
final class InterstitialAdManager: NSObject, ObservableObject {
    static let shared = InterstitialAdManager()
    
    @Published private(set) var isAdReady = false
    @Published private(set) var isShowingAd = false
    
    private var interstitialAd: InterstitialAd?
    private var onDismissCompletion: (() -> Void)?
    
    private override init() {
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
        
        // 更安全地在 SwiftUI 中尋找 Top ViewController
        if let windowScene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene,
           let rootVC = windowScene.windows.first(where: { $0.isKeyWindow })?.rootViewController {
            
            var topController = rootVC
            while let presented = topController.presentedViewController {
                topController = presented
            }
            ad.present(from: topController)
        } else {
            // 備用方案
            ad.present(from: nil)
        }
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
