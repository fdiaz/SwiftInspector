// Created by Francisco Diaz on 10/15/19.
// Copyright © 2019 Airbnb Inc. All rights reserved.

import Commandant
import Foundation

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
    return .success(())
  }

}

/// A type that represents parameters that can be passed to the SingletonUsageCommand command
struct SingletonUsageOptions: OptionsProtocol {
  fileprivate let typeName: String
  fileprivate let variableName: String
  fileprivate let path: String

  /// Evaluates the arguments passed through the CommandMode and converts them into a valid SingletonUsageOptions
  ///
  /// - Parameter m: The `CommandMode` that's used to parse the command line arguments into a strongly typed `SingletonUsageOptions`
  /// - Returns: A valid SingletonUsageOptions or an error
  static func evaluate(_ m: CommandMode) -> Result<SingletonUsageOptions, CommandantError<Error>> {
    let result: Result<SingletonUsageOptions, CommandantError<Error>> = create
      <*> m <| Option(key: "type-name", defaultValue: "", usage: "the name of the type")
      <*> m <| Option(key: "variable-name", defaultValue: "", usage: "the name of the variable")
      <*> m <| Option(key: "path", defaultValue: "", usage: "the path to the Swift file to inspect")

    return result.flatMap { return validate($0) }
  }

  private static func create(_ typeName: String) -> (String) -> (String) -> SingletonUsageOptions {
    return { variableName in { path in SingletonUsageOptions(typeName: typeName, variableName: variableName, path: path) } }
  }

  private static func validate(_ options: SingletonUsageOptions) -> Result<SingletonUsageOptions, CommandantError<Error>> {
    guard !options.typeName.isEmpty else { return .failure(.usageError(description: "type-name can't be empty")) }
    guard !options.variableName.isEmpty else { return .failure(.usageError(description: "variable-name can't be empty")) }
    guard !options.path.isEmpty else { return .failure(.usageError(description: "path can't be empty")) }

    return .success(options)
  }
}
