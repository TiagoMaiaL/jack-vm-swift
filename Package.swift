// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "jackvm",
    platforms: [.macOS(.v13)],
    products: [
        .executable(
            name: "JackVM",
            targets: ["JackVM"]
        )
    ],
    dependencies: [
        .package(
            url: "https://github.com/apple/swift-argument-parser",
            from: "1.3.0"
        )
    ],
    targets: [
        .executableTarget(
            name: "JackVM",
            dependencies: [
                .product(
                    name: "ArgumentParser",
                    package: "swift-argument-parser"
                )
            ]
        ),
        .testTarget(
            name: "JackVMTests",
            dependencies: ["JackVM"]
        )
    ]
)
