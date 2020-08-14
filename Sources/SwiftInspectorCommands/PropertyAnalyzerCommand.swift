// Created by Tyler Hedrick on 8/17/20.
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

final class PropertyAnalyzerCommand: ParsableCommand {
  static var configuration = CommandConfiguration(
    commandName: "properties",
    abstract: "Finds property information for the provided type"
  )

  @Option(help: nameArgumentHelp)
  var name: String

  @Option(help: "The absolute path of the file to inspect")
  var path: String

  /// Runs the command
  func run() throws {
    let cachedSyntaxTree = CachedSyntaxTree()

    let analyzer = PropertyAnalyzer(typeName: name, cachedSyntaxTree: cachedSyntaxTree)
    let fileURL = URL(fileURLWithPath: path)
    if let propertyInformation = try analyzer.analyze(fileURL: fileURL) {
      print(outputString(from: propertyInformation))
    }
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

  private func outputString(from statement: TypeWithPropInfo) -> String {
    let propString = statement.properties.map { propInfo in
      "(\(propInfo.name)|\(propInfo.access)|\(propInfo.scope))"
    }.joined(separator: ",")
    return "\(statement.name):\(propString)"
  }
}

private let nameArgumentHelp = ArgumentHelp(
  "The name of the type to find property information on",
  discussion: "This may be a enum, class, struct, or protocol.")
