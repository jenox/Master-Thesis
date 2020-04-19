// swift-tools-version:5.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Modules",
    platforms: [.iOS(.v13), .macOS(.v10_15)],
    products: [
        .executable(name: "Executable", targets: ["Executable"]),
        .library(name: "Geometry", targets: ["Geometry"]),
        .library(name: "Collections", targets: ["Collections"]),
    ],
    dependencies: [
    ],
    targets: [
        .target(name: "Executable", dependencies: ["Geometry", "Collections"]),

        .target(name: "Geometry", dependencies: ["Collections"]),
        .target(name: "Collections", dependencies: []),

        .testTarget(name: "CollectionsTests", dependencies: ["Collections"]),
    ]
)
