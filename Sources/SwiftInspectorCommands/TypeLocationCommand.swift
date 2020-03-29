// Created by Michael Bachand on 3/28/20.
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

final class TypeLocationCommand: ParsableCommand {
  static var configuration = CommandConfiguration(
    commandName: "type-location",
    abstract: "Finds the location of a type"
  )

  @Option(help: nameArgumentHelp)
  var name: String

  @Option(help: "The absolute path to the file to inspect")
  var path: String

  /// Runs the command
  func run() throws {
    let cachedSyntaxTree = CachedSyntaxTree()

    let analyzer = TypeLocationAnalyzer(typeName: name, cachedSyntaxTree: cachedSyntaxTree)
    let fileURL = URL(fileURLWithPath: path)
    let typeLocation = try analyzer.analyze(fileURL: fileURL)

    print(typeLocation?.outputString() ?? "")
  }

  /// Validates if the arguments of this command are valid
  func validate() throws {
    guard !name.isEmpty else {
      throw InspectorError.emptyArgument(argumentName: "--name")
    }
    guard !path.isEmpty else {
      throw InspectorError.emptyArgument(argumentName: "--path")
    }
    var isDir: ObjCBool = false
    guard FileManager.default.fileExists(atPath: path, isDirectory: &isDir) && !isDir.boolValue else {
      throw InspectorError.invalidArgument(argumentName: "--path", value: path)
    }
  }
}

extension TypeLocation {

  func outputString() -> String {
    return "\(indexOfStartingLine) \(indexOfEndingLine)"
  }
}

// We recognize that a protocol may not strictly be a type, but we're OK with cutting that corner
// for now...
private let nameArgumentHelp = ArgumentHelp(
  "The name of the type to find the location of",
  discussion: "This may be a enum, class, struct, or protocol.")
