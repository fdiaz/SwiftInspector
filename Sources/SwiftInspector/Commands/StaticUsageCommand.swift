// Created by Francisco Diaz on 10/15/19.
// Copyright © 2019 Airbnb Inc. All rights reserved.

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
      let results: String = try analyzer.analyze(fileURL: fileURL)
      print(results) // Print to standard output
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
