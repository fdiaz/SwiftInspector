// Created by Francisco Diaz on 3/25/20.
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
import SwiftInspectorCore

final class TypealiasCommand: ParsableCommand {
  static var configuration = CommandConfiguration(
    commandName: "typealias",
    abstract: "Finds information related to the declaration of a typelias"
  )

  @Option(default: "", help: Help.name)
  var name: String

  @Option(help: "The absolute path to the file to inspect")
  var path: String

  /// Runs the command
  func run() throws {
    let cachedSyntaxTree = CachedSyntaxTree()
    let analyzer = TypealiasAnalyzer(cachedSyntaxTree: cachedSyntaxTree)
    let fileURL = URL(fileURLWithPath: path)
    let outputArray = try FileManager.default.swiftFiles(at: fileURL)
      .reduce(Set<String>()) { result, url in
        let statements = try analyzer.analyze(fileURL: url)
        let output = filterOutput(statements).map { outputString(from: $0) }
        return result.union(output)
    }

    let output = outputArray.filter { !$0.isEmpty }.joined(separator: "\n")
    print(output)
  }

  /// Validates if the arguments of this command are valid
  func validate() throws {
    guard !path.isEmpty else {
      throw InspectorError.emptyArgument(argumentName: "--path")
    }

    let pathURL = URL(fileURLWithPath: path)
    guard FileManager.default.isSwiftFile(at: pathURL) else {
      throw InspectorError.invalidArgument(argumentName: "--path", value: path)
    }
  }

  /// Filters the output based on command line inputs
  private func filterOutput(_ output: [TypealiasStatement]) -> [TypealiasStatement] {
    guard !name.isEmpty else {
      return output
    }

    return output.filter { $0.name == name }
  }

  private func outputString(from statement: TypealiasStatement) -> String {
    guard !name.isEmpty else {
      return statement.name
    }

    return "\(statement.name) \(statement.identifiers.joined(separator: " "))"
  }
}

private struct Help {
  static var name: ArgumentHelp {
    ArgumentHelp("Used to filter by the name of the typelias",
                 discussion: """
                             If a value is passed, it outputs the name of the typealias and the
                             information of the identifiers being declared in that typealias.
                             """
    )
  }
}
