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

  @Option(help: "The absolute path to the file or directory to inspect")
  var path: String

  @Option(default: .main, help: OutputMode.help)
  var mode: OutputMode

  /// Runs the command
  func run() throws {
    let cachedSyntaxTree = CachedSyntaxTree()
    let analyzer = ImportsAnalyzer(cachedSyntaxTree: cachedSyntaxTree)
    let fileURL = URL(fileURLWithPath: path)

    let outputArray = try FileManager.default.swiftFiles(at: fileURL)
      .reduce(Set<String>()) { result, url in
        let importStatements = try analyzer.analyze(fileURL: url)
        let output = importStatements.map { outputString(from: $0)}
        return result.union(output)
    }

    let output = outputArray.joined(separator: "\n")
    print(output)
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

  private func outputString(from statement: ImportStatement) -> String {
    switch mode {
    case .main:
      return statement.mainModule
    case .full:
      let attribute = statement.attribute.isEmpty ? "" : "@\(statement.attribute)"
      var module = statement.mainModule
      if !statement.submodule.isEmpty {
        module += ".\(statement.submodule)"
      }
      return "\(attribute) \(statement.kind) \(module)"
    }
  }
}

enum OutputMode: String, ExpressibleByArgument, Decodable {
  /// Outputs the main module name only
  case main

  /// Outputs the full import statement
  case full
}

extension OutputMode {
  static var help: ArgumentHelp {
    ArgumentHelp("The granularity of what's outputted",
                 discussion: """
                             If main is passed, it only outputs the main module on the import,
                             ignoring the attribute, kind and submodule.
                             If full is passed, it outputs every property on the import.
                             """
    )
  }
}
