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
    ],
    dependencies: [
    ],
    targets: [
        .target(name: "Geometry", dependencies: []),
        .target(name: "Collections", dependencies: []),
        .target(name: "Delaunay", dependencies: []),
        .target(name: "Framework", dependencies: ["Geometry", "Collections", "Delaunay"]),

        .testTarget(name: "CollectionsTests", dependencies: ["Collections"]),
    ]
)
