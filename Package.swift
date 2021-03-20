// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "BaseCombine",
    platforms: [.iOS(.v13), .macOS(.v10_15)],
    products: [
        .library(
            name: "BaseCombine",
            targets: ["BaseCombine"]),
    ],
    dependencies: [
    ],
    targets: [
        .target(
            name: "BaseCombine",
            dependencies: []),
        .testTarget(
            name: "BaseCombineTests",
            dependencies: ["BaseCombine"]),
    ]
)
