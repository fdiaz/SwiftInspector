// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "SwiftInspector",
  platforms: [
    .macOS(.v10_13)
  ],
  products: [
    .executable(name: "swiftinspector", targets: ["SwiftInspector"]),
    .library(name: "SwiftInspectorCommands", targets: ["SwiftInspectorCommands"]),
    .library(name: "SwiftInspectorAnalyzers", targets: ["SwiftInspectorAnalyzers"]),
    .library(name: "SwiftInspectorVisitors", targets: ["SwiftInspectorVisitors"]),
  ],
  dependencies: [
    .package(url: "https://github.com/apple/swift-argument-parser", .upToNextMinor(from: "0.3.1")),
    .package(name: "SwiftSyntax", url: "https://github.com/apple/swift-syntax.git", .exact("0.50300.0")),
    .package(url: "https://github.com/Quick/Nimble.git", .upToNextMajor(from: "8.0.1")),
    .package(url: "https://github.com/Quick/Quick.git", .upToNextMajor(from: "3.0.0")),
  ],
  targets: [
    .target(
      name: "SwiftInspector",
      dependencies: [
        "SwiftInspectorCommands",
    ]),

    .target(
      name: "SwiftInspectorCommands",
      dependencies: [
        "SwiftInspectorAnalyzers",
        .product(name: "ArgumentParser", package: "swift-argument-parser"),
    ], exclude: ["Tests"]),
    .testTarget(
      name: "SwiftInspectorCommandsTests",
      dependencies: [
        "SwiftInspectorCommands",
        "SwiftInspectorTestHelpers",
        "Nimble",
        "Quick",
    ], path: "Sources/SwiftInspectorCommands/Tests"),

    .target(
      name: "SwiftInspectorAnalyzers",
      dependencies: [
        "SwiftSyntax",
        "SwiftInspectorVisitors",
      ],
      exclude: ["Tests"]),
    .testTarget(
      name: "SwiftInspectorAnalyzersTests",
      dependencies: [
        "SwiftInspectorAnalyzers",
        "SwiftInspectorTestHelpers",
        "SwiftInspectorVisitors",
        "Nimble",
        "Quick",
    ], path: "Sources/SwiftInspectorAnalyzers/Tests"),

    .target(
      name: "SwiftInspectorTestHelpers",
      dependencies: ["SwiftSyntax"],
      exclude: ["Tests"]),
    .testTarget(
      name: "SwiftInspectorTestHelpersTests",
      dependencies: [
        "SwiftInspectorTestHelpers",
        "Nimble",
        "Quick",
    ], path: "Sources/SwiftInspectorTestHelpers/Tests"),

    .target(
      name: "SwiftInspectorVisitors",
      dependencies: ["SwiftSyntax"],
      exclude: ["Tests"]),
    .testTarget(
      name: "SwiftInspectorVisitorsTests",
      dependencies: [
        "SwiftInspectorTestHelpers",
        "SwiftInspectorVisitors",
        "Nimble",
        "Quick",
    ], path: "Sources/SwiftInspectorVisitors/Tests"),
  ]
)
