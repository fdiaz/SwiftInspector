// Created by Francisco Diaz on 3/27/20.
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

final class InitializerCommand: ParsableCommand {
  static var configuration = CommandConfiguration(
    commandName: "initializer",
    abstract: "Finds information about the initializers of the specified type"
  )

  @Option(help: "The absolute path to the file to inspect")
  var path: String

  @Option(help: "The name of the type whose initializer information we'll be looking for")
  var name: String

  @Flag(name: .shortAndLong, default: true, inversion: .prefixedEnableDisable, help: typeOnlyHelp)
  var typeOnly: Bool

  /// Runs the command
  func run() throws {
    let cachedSyntaxTree = CachedSyntaxTree()
    let analyzer = InitializerAnalyzer(name: name, cachedSyntaxTree: cachedSyntaxTree)
    let fileURL = URL(fileURLWithPath: path)

    let initializerStatements = try analyzer.analyze(fileURL: fileURL)
    let outputArray = initializerStatements.map { outputString(from: $0) }

    let output = outputArray.joined(separator: "\n")
    print(output)
  }

  /// Validates if the arguments of this command are valid
  func validate() throws {
    guard !name.isEmpty else {
      throw InspectorError.emptyArgument(argumentName: "--name")
    }
    guard !path.isEmpty else {
      throw InspectorError.emptyArgument(argumentName: "--path")
    }

    let pathURL = URL(fileURLWithPath: path)
    guard FileManager.default.isSwiftFile(at: pathURL) else {
      throw InspectorError.invalidArgument(argumentName: "--path", value: path)
    }
  }

  private func outputString(from statement: InitializerStatement) -> String {
    if typeOnly {
      return statement.parameters.map { $0.typeName }.joined(separator: " ")
    } else {
      return statement.parameters.map { "\($0.name),\($0.typeName)" }.joined(separator: " ")
    }
  }
}

private var typeOnlyHelp = ArgumentHelp("The granularity of the output",
                                        discussion: """
                                        Outputs a list of the type names by default. If disabled it outputs the name of the parameter and the name of the type (e.g. 'foo,Int bar,String')
                                        """)
