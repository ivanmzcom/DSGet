// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "DSGetDomain",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "DSGetDomain",
            targets: ["DSGetDomain"]
        ),
    ],
    targets: [
        .target(
            name: "DSGetDomain",
            dependencies: [],
            path: "Sources/DSGetDomain"
        ),
        .testTarget(
            name: "DSGetDomainTests",
            dependencies: ["DSGetDomain"],
            path: "Tests/DSGetDomainTests"
        ),
    ]
)
