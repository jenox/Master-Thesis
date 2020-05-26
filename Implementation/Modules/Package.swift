// swift-tools-version:5.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Modules",
    platforms: [.iOS(.v13), .macOS(.v10_15)],
    products: [
        .library(name: "Geometry", targets: ["Geometry"]),
        .library(name: "Collections", targets: ["Collections"]),
        .library(name: "Delaunay", targets: ["Delaunay"]),
        .library(name: "Framework", targets: ["Framework"]),

        .executable(name: "Evaluation", targets: ["Evaluation"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "0.0.6"),
    ],
    targets: [
        .target(name: "Geometry", dependencies: []),
        .target(name: "Collections", dependencies: []),
        .target(name: "Delaunay", dependencies: []),
        .target(name: "Framework", dependencies: ["Geometry", "Collections", "Delaunay"]),

        .target(name: "Evaluation", dependencies: ["Framework", "Collections", .product(name: "ArgumentParser", package: "swift-argument-parser")]),

        .testTarget(name: "CollectionsTests", dependencies: ["Collections"]),
    ]
)
