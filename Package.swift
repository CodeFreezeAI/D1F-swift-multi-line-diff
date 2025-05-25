// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "MultiLineDiff",
    platforms: [
        .macOS(.v10_15),
        .iOS(.v13),
        .watchOS(.v6),
        .tvOS(.v13)
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "MultiLineDiff",
            targets: ["MultiLineDiff"]),
        .executable(
            name: "MultiLineDiffRunner",
            targets: ["MultiLineDiffRunner"])
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "MultiLineDiff"),
        .executableTarget(
            name: "MultiLineDiffRunner",
            dependencies: ["MultiLineDiff"]),
        .testTarget(
            name: "MultiLineDiffTests",
            dependencies: ["MultiLineDiff"]
        )
    ]
)
