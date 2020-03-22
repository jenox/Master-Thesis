// swift-tools-version:5.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Delaunay",
    products: [
        .library(name: "Delaunay", targets: ["Delaunay"]),
    ],
    dependencies: [
    ],
    targets: [
        .target(name: "Delaunay", dependencies: []),
    ]
)
