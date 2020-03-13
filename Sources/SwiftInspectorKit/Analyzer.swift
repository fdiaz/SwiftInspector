// Created by Francisco Diaz on 10/23/19.
// Copyright © 2019 Airbnb Inc. All rights reserved.

import Foundation

/// A type that can represent how it is output to stdout
public protocol StandardOutputConvertible {
  /// A textual representation of the output
  var standardOutput: String { get }
}

extension Array: StandardOutputConvertible where Element: StandardOutputConvertible {
  // Defaults to a new line per output
  public var standardOutput: String {
    return self.map { $0.standardOutput }.joined(separator: "\n")
  }
}

/// A protocol that defines how to analyze a Swift file from an URL and converts it into a generic output
public protocol Analyzer {
  associatedtype Output: StandardOutputConvertible

  /// Analyzes a Swift file and returns an StandardOutputConvertible output
  /// - Parameter fileURL: The fileURL where the Swift file is located
  func analyze(fileURL: URL) throws -> Output

  /// Analyzes a Swift file and returns a String
  /// - Parameter fileURL: The fileURL where the Swift file is located
  func analyze(fileURL: URL) throws -> String
}

public extension Analyzer {
  func analyze(fileURL: URL) throws -> String {
    let output: Output = try analyze(fileURL: fileURL)
    return output.standardOutput
  }
}
