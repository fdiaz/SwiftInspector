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

  @Option(name: .customLong("type-names"))
  var typeNameString: String

  @Option()
  var path: String

  /// Runs the command
  func run() throws {
    let options = TypeConformanceOptions(typeNameString: typeNameString, path: path)
    try options.validate()

    let cachedSyntaxTree = CachedSyntaxTree()

    for typeName in options.typeNames {
      let analyzer = TypeConformanceAnalyzer(typeName: typeName, cachedSyntaxTree: cachedSyntaxTree)
      let fileURL = URL(fileURLWithPath: options.path)
      let results: String = try analyzer.analyze(fileURL: fileURL)
      print(results) // Print to standard output
    }
  }

}

/// A type that represents parameters that can be passed to the TypeConformanceCommand command
struct TypeConformanceOptions {
  fileprivate let typeNames: [String]
  fileprivate let path: String

  init(typeNameString: String, path: String) {
    typeNames = typeNameString
    .split(separator: ",")
    .map { String($0) }

    self.path = path
  }

  func validate() throws {
    guard !typeNames.isEmpty else {
      throw ValidationError.emptyArgument(argumentName: "--type-names")
    }
    guard !path.isEmpty else {
      throw ValidationError.emptyArgument(argumentName: "--path")
    }
    guard FileManager.default.fileExists(atPath: path) else {
      throw ValidationError.invalidArgument(argumentName: "--path", value: path)
    }
  }
}
