// swift-tools-version:5.5

import PackageDescription

let package = Package(
    name: "FunAsync",
    platforms: [.macOS(.v10_15), .iOS(.v13), .watchOS(.v6), .tvOS(.v13)],
    products: [
        .library(
            name: "FunAsync",
            targets: ["FunAsync"]),
    ],
    dependencies: [
    ],
    targets: [
        .target(
            name: "FunAsync",
            dependencies: []),
        .testTarget(
            name: "FunAsyncTests",
            dependencies: ["FunAsync"]),
    ]
)
