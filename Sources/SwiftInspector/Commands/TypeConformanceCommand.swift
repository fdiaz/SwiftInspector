// Created by Francisco Diaz on 10/11/19.
// Copyright © 2019 Airbnb Inc. All rights reserved.

import ArgumentParser
import Foundation
import SwiftInspectorKit

final class TypeConformanceCommand: ParsableCommand {

  static var configuration = CommandConfiguration(
    commandName: "type-conformance",
    abstract: "Finds information related to the conformance to a type name"
  )

  @Option(name: .customLong("type-names"), parsing: .upToNextOption)
  var typeNames: [String]

  @Option()
  var path: String

  /// Runs the command
  func run() throws {
    let cachedSyntaxTree = CachedSyntaxTree()

    for typeName in typeNames {
      let analyzer = TypeConformanceAnalyzer(typeName: typeName, cachedSyntaxTree: cachedSyntaxTree)
      let fileURL = URL(fileURLWithPath: path)
      let results: String = try analyzer.analyze(fileURL: fileURL)
      print(results) // Print to standard output
    }
  }

  /// Validates if the arguments of this command are valid
  func validate() throws {
    guard !typeNames.isEmpty else {
      throw InspectorError.emptyArgument(argumentName: "--type-names")
    }
    guard !path.isEmpty else {
      throw InspectorError.emptyArgument(argumentName: "--path")
    }
    guard FileManager.default.fileExists(atPath: path) else {
      throw InspectorError.invalidArgument(argumentName: "--path", value: path)
    }
  }

}
