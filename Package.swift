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
    ],
    targets: [
        .target(
            name: "ShakeHealth",
            dependencies: [
                .product(name: "FirebaseFirestore", package: "firebase-ios-sdk"),
                .product(name: "FirebaseAuth", package: "firebase-ios-sdk"),
            ]
        ),
        .testTarget(
            name: "ShakeHealthTests",
            dependencies: ["ShakeHealth"]
        ),
    ]
)
