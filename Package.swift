// swift-tools-version:5.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "SwiftInspector",
  platforms: [
    .macOS(.v10_13)
  ],
  products: [
    .executable(name: "SwiftInspector", targets: ["SwiftInspector"]),
    .library(name: "SwiftInspectorKit", targets: ["SwiftInspectorKit"])
  ],
  dependencies: [
    .package(url: "https://github.com/apple/swift-argument-parser", .upToNextMinor(from: "0.0.1")),
    .package(url: "https://github.com/apple/swift-syntax.git", .exact("0.50100.0")),
    .package(url: "https://github.com/Carthage/Commandant.git", from: "0.17.0"),
    .package(url: "https://github.com/Quick/Nimble.git", .upToNextMajor(from: "8.0.1")),
    .package(url: "https://github.com/Quick/Quick.git", .upToNextMajor(from: "2.0.0")),
  ],
  targets: [
    .target(
      name: "SwiftInspector",
      dependencies: [
        "SwiftInspectorKit",
        "Commandant",
        .product(name: "ArgumentParser", package: "swift-argument-parser"),
    ]),
    .testTarget(
      name: "SwiftInspectorTests",
      dependencies: [
        "SwiftInspector",
        "Nimble",
        "Quick",
    ]),
    .target(
      name: "SwiftInspectorKit",
      dependencies: ["SwiftSyntax"]),
    .testTarget(
      name: "SwiftInspectorKitTests",
      dependencies: [
        "SwiftInspectorKit",
        "Nimble",
        "Quick",
    ]),
  ]
)
