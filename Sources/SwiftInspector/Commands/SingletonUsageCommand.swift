// Created by Francisco Diaz on 10/15/19.
// Copyright © 2019 Airbnb Inc. All rights reserved.

import Commandant
import Foundation
import SwiftInspectorKit

/// A type that represents a CLI command to check for usage of a singleton
final class SingletonUsageCommand: CommandProtocol {
  init() { }

  /// The verb that's used in the command line to invoke this command
  let verb: String = "singleton"
  /// A description of the usage of this command
  let function: String = "Finds information related to the usage of a specific singleton"

  /// Runs the command
  ///
  /// - Parameter options: The available options for this command
  /// - Returns: An Result with an error
  func run(_ options: SingletonUsageOptions) -> Result<(), Error> {
    let cachedSyntaxTree = CachedSyntaxTree()

    return Result {
      for singleton in options.singletons {
        let analyzer = SingletonUsageAnalyzer(singleton: singleton, cachedSyntaxTree: cachedSyntaxTree)
        let fileURL = URL(fileURLWithPath: options.path)
        let results: RawJSON = try analyzer.analyze(fileURL: fileURL)
        print(results) // Print to standard output
      }
      return ()
    }
  }

}

/// A type that represents parameters that can be passed to the SingletonUsageCommand command
struct SingletonUsageOptions: OptionsProtocol {
  fileprivate let singletons: [Singleton]
  fileprivate let path: String

  /// Evaluates the arguments passed through the CommandMode and converts them into a valid SingletonUsageOptions
  ///
  /// - Parameter m: The `CommandMode` that's used to parse the command line arguments into a strongly typed `SingletonUsageOptions`
  /// - Returns: A valid SingletonUsageOptions or an error
  static func evaluate(_ m: CommandMode) -> Result<SingletonUsageOptions, CommandantError<Error>> {
    let result: Result<SingletonUsageOptions, CommandantError<Error>> = create
      <*> m <| Option(key: "singleton", defaultValue: "", usage: "the name of the singleton e.g. Type.member. You can pass multiple values, comma separated")
      <*> m <| Option(key: "path", defaultValue: "", usage: "the path to the Swift file to inspect")

    return result.flatMap { return validate($0) }
  }

  private static func create(_ singletonName: String) -> (String) -> SingletonUsageOptions {
    // Represents an array of singletons in the form ["TypeA.nameA", "TypeB.nameB"]
    //
    // We allow the following patterns as user input:
    // - A single value "SomeType.shared"
    // - A list of values, comma separated: "SomeType.shared,AnotherType.shared"
    // - A list of values, comma separated with empty space "SomeType.shared, AnotherType.shared"
    let rawSingletonsArray: [String] = singletonName
    .replacingOccurrences(of: " ", with: "")
    .split(separator: ",")
    .map { String($0) }

    let singletons: [Singleton] = rawSingletonsArray.reduce(into: []) { (result, value) in
      let splitted = value.split(separator: ".").map { String($0) }
      // We need a type and a member from the arguments. Let's fail if this doesn't happen
      precondition(splitted.count == 2, "The value \(value) is not possible to be split in the form Type.member")
      result.append(Singleton(typeName: splitted.first!, memberName: splitted.last!))
    }

    return { path in SingletonUsageOptions(singletons: singletons, path: path) }
  }

  private static func validate(_ options: SingletonUsageOptions) -> Result<SingletonUsageOptions, CommandantError<Error>> {
    guard !options.singletons.isEmpty else { return .failure(.usageError(description: "Please provide a --singleton argument")) }
    guard !options.path.isEmpty else { return .failure(.usageError(description: "Please provide a --path")) }
    guard FileManager.default.fileExists(atPath: options.path) else { return .failure(.usageError(description: "The provided --path \(options.path) does not exist")) }

    return .success(options)
  }
}
