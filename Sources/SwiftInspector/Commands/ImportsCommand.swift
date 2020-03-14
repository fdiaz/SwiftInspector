// Created by Francisco Diaz on 3/11/20.
// Copyright © 2020 Airbnb Inc. All rights reserved.

import ArgumentParser
import Foundation
import SwiftInspectorKit

final class ImportsCommand: ParsableCommand {
  static var configuration = CommandConfiguration(
    commandName: "imports",
    abstract: "Finds all the declared imports"
  )

  @Option()
  var path: String

  /// Runs the command
  func run() throws {
    let cachedSyntaxTree = CachedSyntaxTree()
    let analyzer = ImportsAnalyzer(cachedSyntaxTree: cachedSyntaxTree)
    let fileURL = URL(fileURLWithPath: path)
    let results: [ImportStatement] = try analyzer.analyze(fileURL: fileURL)
    output(from: results)
  }

    /// Validates if the arguments of this command are valid
  func validate() throws {
    guard !path.isEmpty else {
      throw InspectorError.emptyArgument(argumentName: "--path")
    }
    guard FileManager.default.fileExists(atPath: path) else {
      throw InspectorError.invalidArgument(argumentName: "--path", value: "options.path")
    }
  }

   // Outputs to standard output
  private func output(from imports: [ImportStatement]) {
    let output = imports.map { $0.mainModule }.joined(separator: "\n")
    print(output)
  }
}

