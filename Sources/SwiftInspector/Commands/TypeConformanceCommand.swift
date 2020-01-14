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
    let cachedSyntaxTree = CachedSyntaxTree()

    return Result {
      for typeName in options.typeNames {
        let analyzer = TypeConformanceAnalyzer(typeName: typeName, cachedSyntaxTree: cachedSyntaxTree)
        let fileURL = URL(fileURLWithPath: options.path)
        let results: RawJSON = try analyzer.analyze(fileURL: fileURL)
        print(results) // Print to standard output
      }
      return ()
    }
  }

}

/// A type that represents parameters that can be passed to the TypeConformanceCommand command
struct TypeConformanceOptions: OptionsProtocol {
  fileprivate let typeNames: [String]
  fileprivate let path: String

  /// Evaluates the arguments passed through the CommandMode and converts them into a valid TypeConformanceOptions
  ///
  /// - Parameter m: The `CommandMode` that's used to parse the command line arguments into a strongly typed `TypeConformanceOptions`
  /// - Returns: A valid TypeConformanceOptions or an error
  static func evaluate(_ m: CommandMode) -> Result<TypeConformanceOptions, CommandantError<Error>> {
    let result: Result<TypeConformanceOptions, CommandantError<Error>> = create
      <*> m <| Option(key: "type-names", defaultValue: "", usage: "the name of the type(s) to find conformance to, comma separated")
      <*> m <| Option(key: "path", defaultValue: "", usage: "the path to the Swift file to inspect")

    return result.flatMap { return validate($0) }
  }

  private static func create(_ commaSeparatedTypeNames: String) -> (String) -> TypeConformanceOptions {
    // We allow the following patterns:
    // - A single type "SomeType"
    // - A list of types, comma separated: "SomeType,AnotherType"
    // - A list of types, comma separated with empty space "SomeType, AnotherType"
    let typeNamesArray: [String] = commaSeparatedTypeNames
      .replacingOccurrences(of: " ", with: "")
      .split(separator: ",")
      .map { String($0) }
    return { TypeConformanceOptions(typeNames: typeNamesArray, path: $0) }
  }

  private static func validate(_ options: TypeConformanceOptions) -> Result<TypeConformanceOptions, CommandantError<Error>> {
    guard !options.typeNames.isEmpty else { return .failure(.usageError(description: "Please provide at least a single --type-names")) }
    guard !options.path.isEmpty else { return .failure(.usageError(description: "Please provide a --path")) }
    guard FileManager.default.fileExists(atPath: options.path) else { return .failure(.usageError(description: "The provided --path \(options.path) does not exist")) }

    return .success(options)
  }
}
