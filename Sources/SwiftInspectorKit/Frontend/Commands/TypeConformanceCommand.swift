// Created by Francisco Diaz on 10/11/19.
// Copyright © 2019 Airbnb Inc. All rights reserved.

import Commandant
import Foundation

/// A type that represents a CLI command to check for conformance of a specific type
public final class TypeConformanceCommand: CommandProtocol {
  public init() { }

  /// The verb that's used in the command line to invoke this command
  public let verb: String = "type-conformance"
  /// A description of the usage of this command
  public let function: String = "Finds information related to the conformance to a type name"

  /// Runs the command
  ///
  /// - Parameter options: The available options for this command
  /// - Returns: An Result with an error
  public func run(_ options: TypeConformanceOptions) -> Result<(), Error> {
    return .success(())
  }

}

/// A type that represents parameters that can be passed to the TypeConformanceCommand command
public struct TypeConformanceOptions: OptionsProtocol {
  fileprivate let typeName: String
  fileprivate let path: String

  /// Evaluates the arguments passed through the CommandMode and converts them into a valid TypeConformanceOptions
  ///
  /// - Parameter m: The `CommandMode` that's used to parse the command line arguments into a strongly typed `TypeConformanceOptions`
  /// - Returns: A valid TypeConformanceOptions or an error
  public static func evaluate(_ m: CommandMode) -> Result<TypeConformanceOptions, CommandantError<Error>> {
    let result: Result<TypeConformanceOptions, CommandantError<Error>> = create
      <*> m <| Option(key: "type-name", defaultValue: "", usage: "the name of the type")
      <*> m <| Option(key: "path", defaultValue: "", usage: "the path to the Swift file to inspect")

    return result.flatMap { return validate($0) }
  }

  private static func create(_ typeName: String) -> (String) -> TypeConformanceOptions {
    return { TypeConformanceOptions(typeName: typeName, path: $0) }
  }

  private static func validate(_ options: TypeConformanceOptions) -> Result<TypeConformanceOptions, CommandantError<Error>> {
    guard !options.typeName.isEmpty else { return .failure(.usageError(description: "type-name can't be empty")) }
    guard !options.path.isEmpty else { return .failure(.usageError(description: "path can't be empty")) }

    return .success(options)
  }
}
