// Created by Francisco Diaz on 10/15/19.
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
import SwiftInspectorKit

final class StaticUsageCommand: ParsableCommand {

  static var configuration = CommandConfiguration(
    commandName: "static-usage",
    abstract: "Finds information related to the usage of a static member of a type"
  )

  @Option(parsing: .upToNextOption, transform: StaticMember.make)
  var statics: [StaticMember]

  @Option()
  var path: String

  /// Runs the command
  func run() throws {
    let cachedSyntaxTree = CachedSyntaxTree()

    for staticMember in statics {
      let analyzer = StaticUsageAnalyzer(staticMember: staticMember, cachedSyntaxTree: cachedSyntaxTree)
      let fileURL = URL(fileURLWithPath: path)
      let result: StaticUsage = try analyzer.analyze(fileURL: fileURL)
      output(from: result)
    }
  }

  /// Validates if the arguments of this command are valid
  func validate() throws {
    guard !statics.isEmpty else {
      throw InspectorError.emptyArgument(argumentName: "--statics")
    }
    guard !path.isEmpty else {
      throw InspectorError.emptyArgument(argumentName: "--path")
    }
    guard FileManager.default.fileExists(atPath: path) else {
      throw InspectorError.invalidArgument(argumentName: "--path", value: "options.path")
    }
  }

  /// Outputs to standard output
  private func output(from staticUsage: StaticUsage) {
    print("\(path) \(staticUsage.staticMember.typeName).\(staticUsage.staticMember.memberName) \(staticUsage.isUsed)")
  }
}

private extension StaticMember {
  static func make(argument: String) throws -> StaticMember {
    let splitted = argument.split(separator: ".").map { String($0) }
    // We need a type and a member from the arguments. Let's fail if this doesn't happen
    guard
      let type = splitted.first,
      let member = splitted.last,
      splitted.count == 2
      else
    {
      throw InspectorError.invalidArgument(argumentName: "--statics", value: argument)
    }

    return StaticMember(typeName: type, memberName: member)
  }
}
