// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "DSGetData",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "DSGetData",
            targets: ["DSGetData"]
        ),
    ],
    dependencies: [
        .package(path: "../DSGetDomain")
    ],
    targets: [
        .target(
            name: "DSGetData",
            dependencies: ["DSGetDomain"],
            path: "Sources/DSGetData"
        ),
        .testTarget(
            name: "DSGetDataTests",
            dependencies: ["DSGetData"],
            path: "Tests/DSGetDataTests"
        ),
    ]
)
