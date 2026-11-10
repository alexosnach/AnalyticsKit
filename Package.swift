// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "AnalyticsKit",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "AnalyticsKit", targets: ["AnalyticsKit"]),
    ],
    targets: [
        // Called from the UI: main actor by default, the same in any host app.
        .target(
            name: "AnalyticsKit",
            swiftSettings: [.defaultIsolation(MainActor.self)]
        ),
        .testTarget(
            name: "AnalyticsKitTests",
            dependencies: ["AnalyticsKit"],
            swiftSettings: [.defaultIsolation(MainActor.self)]
        ),
    ]
)
