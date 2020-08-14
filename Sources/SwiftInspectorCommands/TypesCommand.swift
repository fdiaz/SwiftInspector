// Created by Tyler Hedrick on 8/12/20.
//
// Copyright (c) 2020 Tyler Hedrick
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

final class TypesCommand: ParsableCommand {
  static var configuration = CommandConfiguration(
    commandName: "types",
    abstract: "Finds information about types in a file"
  )

  @Option(help: "The absolute path to the file or directory to inspect")
  var path: String

  @Flag(name: .shortAndLong, default: false, inversion: .prefixedEnableDisable, help: commentFlagHelp)
  var includeComments: Bool

  /// Runs the command
  func run() throws {
    let cachedSyntaxTree = CachedSyntaxTree()
    let analyzer = TypesAnalyzer(cachedSyntaxTree: cachedSyntaxTree)
    let fileURL = URL(fileURLWithPath: path)
    let outputArray = try FileManager.default.swiftFiles(at: fileURL)
      .reduce(Set<String>()) { result, url in
        let statements = try analyzer.analyze(fileURL: url)
        let output = statements.map { outputString(from: $0) }
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
    guard FileManager.default.isSwiftFile(at: pathURL) || pathURL.hasDirectoryPath else {
      throw InspectorError.invalidArgument(argumentName: "--path", value: path)
    }
  }

  private func outputString(from info: TypeInfo) -> String {
    guard
      includeComments,
      !info.comment.isEmpty,
      let comment = info.comment.addingPercentEncoding(withAllowedCharacters: NSCharacterSet.newlines.inverted) else
    {
      return "\(info.name),\(info.type)"
    }
    return "\(info.name),\(info.type),\(comment)"
  }
}

private var commentFlagHelp = ArgumentHelp(
  "The granularity of the output",
  discussion: """
             Outputs type names with type information by deafult. If enabled,
             also outputs comments associated with each of these types
             """)
