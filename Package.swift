// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "jackvm",
    products: [
        .library(
            name: "JackVM",
            targets: ["JackVM"]
        ),
    ],
    targets: [
        .target(
            name: "JackVM"
        ),
        .testTarget(
            name: "JackVMTests",
            dependencies: ["JackVM"]
        ),
    ]
)
