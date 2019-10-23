// Created by Francisco Diaz on 10/23/19.
// Copyright © 2019 Airbnb Inc. All rights reserved.

import Foundation

public typealias RawJSON = String

/// A protocol that defines how to analyze a Swift file from an URL and converts it into a generic output
public protocol Analyzer {
  associatedtype Output: Encodable

  /// Analyzes a Swift file and returns an Encodable output
  /// - Parameter fileURL: The fileURL where the Swift file is located
  func analyze(fileURL: URL) throws -> Output

  /// Analyzes a Swift file and returns a RawJSON
  /// - Parameter fileURL: The fileURL where the Swift file is located
  func analyze(fileURL: URL) throws -> RawJSON
}

public extension Analyzer {
  func analyze(fileURL: URL) throws -> RawJSON {
    let encodable: Output = try analyze(fileURL: fileURL)
    let jsonData = try JSONEncoder().encode(encodable)
    return String(decoding: jsonData, as: UTF8.self)
  }
}
