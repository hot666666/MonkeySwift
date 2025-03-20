// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "MonkeySwift",
    products: [
        .executable(name: "MonkeySwift", targets: ["MonkeySwift"])
    ],
    targets: [
        .executableTarget(
            name: "MonkeySwift",
            path: "Sources/MonkeySwift"
        ),
        .testTarget(
            name: "MonkeySwiftTests",
            dependencies: ["MonkeySwift"],
            path: "Tests/MonkeySwiftTests"
        ),
    ]
)
