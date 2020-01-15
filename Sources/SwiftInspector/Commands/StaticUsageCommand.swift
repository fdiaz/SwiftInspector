// Created by Francisco Diaz on 10/15/19.
// Copyright © 2019 Airbnb Inc. All rights reserved.

import Commandant
import Foundation
import SwiftInspectorKit

/// A type that represents a CLI command to check for usage of a static member of a type
final class StaticUsageCommand: CommandProtocol {
  init() { }

  /// The verb that's used in the command line to invoke this command
  let verb: String = "static-usage"
  /// A description of the usage of this command
  let function: String = "Finds information related to the usage of a static member of a type"

  /// Runs the command
  ///
  /// - Parameter options: The available options for this command
  /// - Returns: An Result with an error
  func run(_ options: StaticUsageOptions) -> Result<(), Error> {
    let cachedSyntaxTree = CachedSyntaxTree()

    return Result {
      for staticMember in options.staticMembers {
        let analyzer = StaticUsageAnalyzer(staticMember: staticMember, cachedSyntaxTree: cachedSyntaxTree)
        let fileURL = URL(fileURLWithPath: options.path)
        let results: RawJSON = try analyzer.analyze(fileURL: fileURL)
        print(results) // Print to standard output
      }
      return ()
    }
  }

}

/// A type that represents parameters that can be passed to the StaticUsageCommand command
struct StaticUsageOptions: OptionsProtocol {
  fileprivate let staticMembers: [StaticMember]
  fileprivate let path: String

  /// Evaluates the arguments passed through the CommandMode and converts them into a valid StaticUsageOptions
  ///
  /// - Parameter m: The `CommandMode` that's used to parse the command line arguments into a strongly typed `StaticUsageOptions`
  /// - Returns: A valid StaticUsageOptions or an error
  static func evaluate(_ m: CommandMode) -> Result<StaticUsageOptions, CommandantError<Error>> {
    let result: Result<StaticUsageOptions, CommandantError<Error>> = create
      <*> m <| Option(key: "statics", defaultValue: "", usage: "the name of the static members e.g. Type.member. You can pass multiple values, comma separated")
      <*> m <| Option(key: "path", defaultValue: "", usage: "the path to the Swift file to inspect")

    return result.flatMap { return validate($0) }
  }

  private static func create(_ staticMemberName: String) -> (String) -> StaticUsageOptions {
    // Represents an array of static members in the form ["TypeA.nameA", "TypeB.nameB"]
    //
    // We allow the following patterns as user input:
    // - A single value "SomeType.shared"
    // - A list of values, comma separated: "SomeType.shared,AnotherType.shared"
    // - A list of values, comma separated with empty space "SomeType.shared, AnotherType.shared"
    let rawStaticsArray: [String] = staticMemberName
    .replacingOccurrences(of: " ", with: "")
    .split(separator: ",")
    .map { String($0) }

    let staticMembers: [StaticMember] = rawStaticsArray.reduce(into: []) { (result, value) in
      let splitted = value.split(separator: ".").map { String($0) }
      // We need a type and a member from the arguments. Let's fail if this doesn't happen
      precondition(splitted.count == 2, "The value \(value) is not possible to be split in the form Type.member")
      result.append(StaticMember(typeName: splitted.first!, memberName: splitted.last!))
    }

    return { path in StaticUsageOptions(staticMembers: staticMembers, path: path) }
  }

  private static func validate(_ options: StaticUsageOptions) -> Result<StaticUsageOptions, CommandantError<Error>> {
    guard !options.staticMembers.isEmpty else { return .failure(.usageError(description: "Please provide a --statics argument")) }
    guard !options.path.isEmpty else { return .failure(.usageError(description: "Please provide a --path")) }
    guard FileManager.default.fileExists(atPath: options.path) else { return .failure(.usageError(description: "The provided --path \(options.path) does not exist")) }

    return .success(options)
  }
}
