// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "DSGetCore",
    platforms: [
        .iOS(.v18),
        .watchOS(.v11),
        .macOS(.v15)
    ],
    products: [
        .library(
            name: "DSGetCore",
            targets: ["DSGetCore"]
        )
    ],
    targets: [
        .target(
            name: "DSGetCore",
            dependencies: []
        )
    ]
)
