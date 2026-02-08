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
                    GADBannerViewRepresentable()
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

// MARK: - GADBannerView Representable

/// UIKit GADBannerView 的 SwiftUI 包裝器
struct GADBannerViewRepresentable: UIViewRepresentable {
    
    func makeUIView(context: Context) -> GADBannerView {
        let bannerView = GADBannerView(adSize: GADAdSizeBanner)
        bannerView.adUnitID = AdManager.shared.bannerAdUnitID
        bannerView.delegate = context.coordinator
        
        // 設定根視圖控制器
        if let rootVC = UIApplication.shared.rootViewController {
            bannerView.rootViewController = rootVC
        }
        
        // 載入廣告
        let request = GADRequest()
        bannerView.load(request)
        
        return bannerView
    }
    
    func updateUIView(_ uiView: GADBannerView, context: Context) {
        // 不需要更新
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator: NSObject, GADBannerViewDelegate {
        func bannerViewDidReceiveAd(_ bannerView: GADBannerView) {
            print("✅ Banner 廣告載入成功")
        }
        
        func bannerView(_ bannerView: GADBannerView, didFailToReceiveAdWithError error: Error) {
            print("❌ Banner 廣告載入失敗: \(error.localizedDescription)")
        }
    }
}

// MARK: - Native Ad View

/// 原生廣告視圖
/// 用於圖鑑列表中每 N 項插入
struct NativeAdView: View {
    @EnvironmentObject var userManager: UserManager
    @StateObject private var adLoader = NativeAdLoader()
    
    var body: some View {
        // Pro 用戶不顯示廣告
        if !userManager.isProUser {
            if adLoader.nativeAd != nil {
                GADNativeAdViewRepresentable(nativeAd: adLoader.nativeAd!)
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

// MARK: - Native Ad Loader

/// 原生廣告載入器
@MainActor
class NativeAdLoader: NSObject, ObservableObject {
    @Published var nativeAd: GADNativeAd?
    @Published var isLoading = false
    
    private var adLoader: GADAdLoader?
    
    func loadAd() {
        guard !isLoading, nativeAd == nil else { return }
        
        isLoading = true
        
        let options = GADNativeAdMediaAdLoaderOptions()
        options.mediaAspectRatio = .landscape
        
        adLoader = GADAdLoader(
            adUnitID: AdManager.shared.nativeAdUnitID,
            rootViewController: UIApplication.shared.rootViewController,
            adTypes: [.native],
            options: [options]
        )
        adLoader?.delegate = self
        adLoader?.load(GADRequest())
    }
}

extension NativeAdLoader: GADNativeAdLoaderDelegate {
    nonisolated func adLoader(_ adLoader: GADAdLoader, didReceive nativeAd: GADNativeAd) {
        Task { @MainActor in
            self.nativeAd = nativeAd
            self.isLoading = false
            print("✅ Native 廣告載入成功")
        }
    }
    
    nonisolated func adLoader(_ adLoader: GADAdLoader, didFailToReceiveAdWithError error: Error) {
        Task { @MainActor in
            self.isLoading = false
            print("❌ Native 廣告載入失敗: \(error.localizedDescription)")
        }
    }
}

// MARK: - GADNativeAdView Representable

/// UIKit GADNativeAdView 的 SwiftUI 包裝器
struct GADNativeAdViewRepresentable: UIViewRepresentable {
    let nativeAd: GADNativeAd
    
    func makeUIView(context: Context) -> GADNativeAdView {
        let nativeAdView = GADNativeAdView()
        
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
    
    func updateUIView(_ uiView: GADNativeAdView, context: Context) {
        uiView.nativeAd = nativeAd
        (uiView.headlineView as? UILabel)?.text = nativeAd.headline
        (uiView.bodyView as? UILabel)?.text = nativeAd.body
    }
}

// MARK: - Preview

#Preview {
    VStack {
        NativeAdView()
            .padding()
        
        Spacer()
        
        BannerAdView()
    }
    .environmentObject(UserManager.shared)
}
