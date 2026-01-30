import Foundation
import UIKit

/// Google Maps 服務
struct MapService {
    /// 開啟 Google Maps 搜尋附近店家
    static func searchNearby(brand: String) {
        let searchQuery = "\(brand) 飲料店"
        guard let encodedQuery = searchQuery.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            return
        }
        
        // 優先使用 Google Maps App
        if let url = URL(string: "\(Constants.Maps.googleMapsScheme)?q=\(encodedQuery)"),
           UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        }
        // Fallback 到網頁版
        else if let webURL = URL(string: "\(Constants.Maps.googleMapsWebURL)?api=1&query=\(encodedQuery)") {
            UIApplication.shared.open(webURL)
        }
    }
    
    /// 開啟 Apple Maps 作為備用
    static func openAppleMaps(brand: String) {
        let searchQuery = "\(brand) 飲料店"
        guard let encodedQuery = searchQuery.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "maps://?q=\(encodedQuery)") else {
            return
        }
        UIApplication.shared.open(url)
    }
}
