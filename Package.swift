// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "MonkeySwift",
    platforms: [
        .macOS(.v12)
    ],
    products: [
        // Executable REPL
        .executable(name: "MonkeySwift", targets: ["MonkeySwift"]),

        // Libraries for modular use
        .library(name: "MonkeyCore", targets: ["MonkeyCore"]),
        .library(name: "MonkeyLexer", targets: ["MonkeyLexer"]),
        .library(name: "MonkeyParser", targets: ["MonkeyParser"]),
        .library(name: "MonkeyEvaluator", targets: ["MonkeyEvaluator"]),
    ],
    targets: [
        // Core module - Token, AST, Object, Environment
        .target(
            name: "MonkeyCore",
            path: "Sources/MonkeyCore"
        ),

        // Lexer module
        .target(
            name: "MonkeyLexer",
            dependencies: ["MonkeyCore"],
            path: "Sources/MonkeyLexer"
        ),

        // Parser module
        .target(
            name: "MonkeyParser",
            dependencies: ["MonkeyCore", "MonkeyLexer"],
            path: "Sources/MonkeyParser"
        ),

        // Evaluator module
        .target(
            name: "MonkeyEvaluator",
            dependencies: ["MonkeyCore"],
            path: "Sources/MonkeyEvaluator"
        ),

        // Main executable
        .executableTarget(
            name: "MonkeySwift",
            dependencies: ["MonkeyCore", "MonkeyLexer", "MonkeyParser", "MonkeyEvaluator"],
            path: "Sources/MonkeySwift"
        ),

        // Tests
        .testTarget(
            name: "MonkeySwiftTests",
            dependencies: ["MonkeyCore", "MonkeyLexer", "MonkeyParser", "MonkeyEvaluator"],
            path: "Tests/MonkeySwiftTests"
        ),
    ]
)
