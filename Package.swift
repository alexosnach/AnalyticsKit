// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "AnalyticsKit",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "AnalyticsKit", targets: ["AnalyticsKit"]),
    ],
    targets: [
        // Nonisolated and Sendable: callable from any actor (UI, StoreKit listeners, background work).
        .target(name: "AnalyticsKit"),
        .testTarget(
            name: "AnalyticsKitTests",
            dependencies: ["AnalyticsKit"]
        ),
    ]
)
