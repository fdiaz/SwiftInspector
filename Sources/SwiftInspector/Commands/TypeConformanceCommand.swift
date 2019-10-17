// Created by Francisco Diaz on 10/11/19.
// Copyright © 2019 Airbnb Inc. All rights reserved.

import Commandant
import Foundation
import SwiftInspectorKit

/// A type that represents a CLI command to check for conformance of a specific type
final class TypeConformanceCommand: CommandProtocol {
  init() { }

  /// The verb that's used in the command line to invoke this command
  let verb: String = "type-conformance"
  /// A description of the usage of this command
  let function: String = "Finds information related to the conformance to a type name"

  /// Runs the command
  ///
  /// - Parameter options: The available options for this command
  /// - Returns: An Result with an error
  func run(_ options: TypeConformanceOptions) -> Result<(), Error> {
    let analyzer = TypeConformanceAnalyzer(typeName: options.typeName)

    return Result {
      let fileURL = URL(fileURLWithPath: options.path)
      let results = try analyzer.analyze(fileURL: fileURL)
      print(results) // Print to standard output
      return ()
    }
  }

}

/// A type that represents parameters that can be passed to the TypeConformanceCommand command
struct TypeConformanceOptions: OptionsProtocol {
  fileprivate let typeName: String
  fileprivate let path: String

  /// Evaluates the arguments passed through the CommandMode and converts them into a valid TypeConformanceOptions
  ///
  /// - Parameter m: The `CommandMode` that's used to parse the command line arguments into a strongly typed `TypeConformanceOptions`
  /// - Returns: A valid TypeConformanceOptions or an error
  static func evaluate(_ m: CommandMode) -> Result<TypeConformanceOptions, CommandantError<Error>> {
    let result: Result<TypeConformanceOptions, CommandantError<Error>> = create
      <*> m <| Option(key: "type-name", defaultValue: "", usage: "the name of the type")
      <*> m <| Option(key: "path", defaultValue: "", usage: "the path to the Swift file to inspect")

    return result.flatMap { return validate($0) }
  }

  private static func create(_ typeName: String) -> (String) -> TypeConformanceOptions {
    return { TypeConformanceOptions(typeName: typeName, path: $0) }
  }

  private static func validate(_ options: TypeConformanceOptions) -> Result<TypeConformanceOptions, CommandantError<Error>> {
    guard !options.typeName.isEmpty else { return .failure(.usageError(description: "Please provide a --type-name")) }
    guard !options.path.isEmpty else { return .failure(.usageError(description: "Please provide a --path")) }
    guard FileManager.default.fileExists(atPath: options.path) else { return .failure(.usageError(description: "The provided --path \(options.path) does not exist")) }

    return .success(options)
  }
}
