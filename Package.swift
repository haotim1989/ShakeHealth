// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ShakeHealth",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "ShakeHealth",
            targets: ["ShakeHealth"]
        ),
    ],
    dependencies: [
        // Firebase SDK
        .package(url: "https://github.com/firebase/firebase-ios-sdk.git", from: "10.0.0"),
        // RevenueCat SDK
        .package(url: "https://github.com/RevenueCat/purchases-ios-spm.git", from: "5.0.0"),
        // Google Mobile Ads SDK
        .package(url: "https://github.com/googleads/swift-package-manager-google-mobile-ads.git", from: "11.0.0"),
    ],
    targets: [
        .target(
            name: "ShakeHealth",
            dependencies: [
                .product(name: "FirebaseFirestore", package: "firebase-ios-sdk"),
                .product(name: "FirebaseAuth", package: "firebase-ios-sdk"),
                .product(name: "RevenueCat", package: "purchases-ios-spm"),
                .product(name: "GoogleMobileAds", package: "swift-package-manager-google-mobile-ads"),
            ],
            path: "Sources"
        ),
        .testTarget(
            name: "ShakeHealthTests",
            dependencies: ["ShakeHealth"],
            path: "Tests"
        ),
    ]
)
