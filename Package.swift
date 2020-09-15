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
    .library(name: "SwiftInspectorCore", targets: ["SwiftInspectorCore"])
  ],
  dependencies: [
    .package(url: "https://github.com/apple/swift-argument-parser", .upToNextMinor(from: "0.0.4")),
    .package(name: "SwiftSyntax", url: "https://github.com/apple/swift-syntax.git", .branch("release/5.3")),
    .package(url: "https://github.com/Quick/Nimble.git", .upToNextMajor(from: "8.0.1")),
    .package(url: "https://github.com/Quick/Quick.git", .upToNextMajor(from: "2.0.0")),
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
        "SwiftInspectorCore",
        .product(name: "ArgumentParser", package: "swift-argument-parser"),
    ], exclude: ["Tests"]),
    .testTarget(
      name: "SwiftInspectorCommandsTests",
      dependencies: [
        "SwiftInspectorCommands",
        "Nimble",
        "Quick",
    ], path: "Sources/SwiftInspectorCommands/Tests"),

    .target(
      name: "SwiftInspectorCore",
      dependencies: ["SwiftSyntax"],
      exclude: ["Tests"]),
    .testTarget(
      name: "SwiftInspectorCoreTests",
      dependencies: [
        "SwiftInspectorCore",
        "Nimble",
        "Quick",
    ], path: "Sources/SwiftInspectorCore/Tests"),
  ]
)
