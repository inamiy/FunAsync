// swift-tools-version:5.5

import PackageDescription

let package = Package(
    name: "FunAsync",
    platforms: [.macOS(.v12), .iOS(.v15), .watchOS(.v8), .tvOS(.v15)],
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
