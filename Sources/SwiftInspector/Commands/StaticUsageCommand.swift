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

  @Option()
  var statics: String

  @Option()
  var path: String

  /// Runs the command
  func run() throws {
    let options = StaticUsageOptions(statics: statics, path: path)
    try options.validate()

    let cachedSyntaxTree = CachedSyntaxTree()

    for staticMember in options.staticMembers {
      let analyzer = StaticUsageAnalyzer(staticMember: staticMember, cachedSyntaxTree: cachedSyntaxTree)
      let fileURL = URL(fileURLWithPath: options.path)
      let results: String = try analyzer.analyze(fileURL: fileURL)
      print(results) // Print to standard output
    }
  }

}

/// A type that represents parameters that can be passed to the StaticUsageCommand command
struct StaticUsageOptions {
  fileprivate let staticMembers: [StaticMember]
  fileprivate let path: String

  /// - Parameter statics: Represents a list of static members.
  ///                      We allow a single value `SomeType.shared` or a list of values,
  ///                      comma separated: `SomeType.shared,AnotherType.shared`
  /// - Parameter path: The path to the Swift file to inspect
  init(statics: String, path: String) {
    let rawStaticsArray: [String] = statics
      .split(separator: ",")
      .map { String($0) }

    let staticMembers: [StaticMember] = rawStaticsArray.reduce(into: []) { (result, value) in
      let splitted = value.split(separator: ".").map { String($0) }
      // We need a type and a member from the arguments. Let's fail if this doesn't happen
      precondition(splitted.count == 2, "The value \(value) is not possible to be split in the form Type.member")
      result.append(StaticMember(typeName: splitted.first!, memberName: splitted.last!))
    }

    self.staticMembers = staticMembers
    self.path = path
  }

  /// Validates if the arguments of this command are valid
  func validate() throws {
    guard !staticMembers.isEmpty else {
      throw ValidationError.emptyArgument(argumentName: "--statics")
    }
    guard !path.isEmpty else {
      throw ValidationError.emptyArgument(argumentName: "--path")
    }
    guard FileManager.default.fileExists(atPath: path) else {
      throw ValidationError.invalidArgument(argumentName: "--path", value: "options.path")
    }
  }
}
