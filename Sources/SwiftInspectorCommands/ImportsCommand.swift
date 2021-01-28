// Created by Francisco Diaz on 3/11/20.
//
// Copyright (c) 2020 Francisco Diaz
//
// Distributed under the MIT License
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

import ArgumentParser
import Foundation
import SwiftInspectorAnalyzers
import SwiftInspectorVisitors

final class ImportsCommand: ParsableCommand {
  static var configuration = CommandConfiguration(
    commandName: "imports",
    abstract: "Finds all the declared imports"
  )

  @Option(help: "The absolute path to the file or directory to inspect")
  var path: String

  @Option(help: OutputMode.help)
  var mode: OutputMode = .main

  /// Runs the command
  func run() throws {
    let cachedSyntaxTree = CachedSyntaxTree()
    let analyzer = StandardAnalyzer(cachedSyntaxTree: cachedSyntaxTree)
    let fileURL = URL(fileURLWithPath: path)

    let outputArray = try FileManager.default.swiftFiles(at: fileURL)
      .reduce(Set<String>()) { result, url in
        let output = try analyzer.analyzeImports(fileURL: url)
          .map { outputString(from: $0) }
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
      throw InspectorError.invalidArgument(argumentName: "--path", value: path)
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
