// swift-tools-version:5.6
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "SwiftInspector",
  platforms: [
    .macOS(.v12)
  ],
  products: [
    .executable(name: "swiftinspector", targets: ["SwiftInspector"]),
    .library(name: "SwiftInspectorAnalyzers", targets: ["SwiftInspectorAnalyzers"]),
    .library(name: "SwiftInspectorVisitors", targets: ["SwiftInspectorVisitors"]),
    .library(name: "SwiftInspectorTestHelpers", targets: ["SwiftInspectorTestHelpers"]),
  ],
  dependencies: [
    .package(url: "https://github.com/apple/swift-argument-parser", from: "1.0.0"),
    .package(url: "https://github.com/apple/swift-syntax.git", exact: "0.50600.1"),
    .package(url: "https://github.com/Quick/Nimble.git", .upToNextMajor(from: "9.0.1")),
    .package(url: "https://github.com/Quick/Quick.git", .upToNextMajor(from: "4.0.0")),
  ],
  targets: [
    .executableTarget(
      name: "SwiftInspector",
      dependencies: [
        "SwiftInspectorCommands",
        "lib_InternalSwiftSyntaxParser",
      ],
      linkerSettings: [.unsafeFlags(["-Xlinker", "-dead_strip_dylibs"])]),

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
      ],
      path: "Sources/SwiftInspectorCommands/Tests",
      linkerSettings: [.unsafeFlags(["-Xlinker", "-rpath", "-Xlinker", "$DT_TOOLCHAIN_DIR/usr/lib/swift/macosx"])]),

    .target(
      name: "SwiftInspectorAnalyzers",
      dependencies: [
        .product(name: "SwiftSyntax", package: "swift-syntax"),
        .product(name: "SwiftSyntaxParser", package: "swift-syntax"),
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
      ],
      path: "Sources/SwiftInspectorAnalyzers/Tests",
      linkerSettings: [.unsafeFlags(["-Xlinker", "-rpath", "-Xlinker", "$DT_TOOLCHAIN_DIR/usr/lib/swift/macosx"])]),

    .target(
      name: "SwiftInspectorTestHelpers",
      dependencies: [
        .product(name: "SwiftSyntax", package: "swift-syntax"),
        .product(name: "SwiftSyntaxParser", package: "swift-syntax"),
      ],
      exclude: ["Tests"]),
    .testTarget(
      name: "SwiftInspectorTestHelpersTests",
      dependencies: [
        "SwiftInspectorTestHelpers",
        "Nimble",
        "Quick",
      ],
      path: "Sources/SwiftInspectorTestHelpers/Tests",
      linkerSettings: [.unsafeFlags(["-Xlinker", "-rpath", "-Xlinker", "$DT_TOOLCHAIN_DIR/usr/lib/swift/macosx"])]),

    .target(
      name: "SwiftInspectorVisitors",
      dependencies: [
        .product(name: "SwiftSyntax", package: "swift-syntax"),
      ],
      exclude: ["Tests"]),
    .testTarget(
      name: "SwiftInspectorVisitorsTests",
      dependencies: [
        "SwiftInspectorTestHelpers",
        "SwiftInspectorVisitors",
        "Nimble",
        "Quick",
      ],
      path: "Sources/SwiftInspectorVisitors/Tests",
      linkerSettings: [.unsafeFlags(["-Xlinker", "-rpath", "-Xlinker", "$DT_TOOLCHAIN_DIR/usr/lib/swift/macosx"])]),

      .binaryTarget(
          name: "lib_InternalSwiftSyntaxParser",
          url: "https://github.com/keith/StaticInternalSwiftSyntaxParser/releases/download/5.6/lib_InternalSwiftSyntaxParser.xcframework.zip",
          checksum: "88d748f76ec45880a8250438bd68e5d6ba716c8042f520998a438db87083ae9d"
      ),
  ]
)
