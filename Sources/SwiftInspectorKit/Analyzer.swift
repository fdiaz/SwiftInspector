// Created by Francisco Diaz on 10/23/19.
// Copyright © 2019 Airbnb Inc. All rights reserved.

import Foundation

/// A protocol that defines how to analyze a Swift file from an URL and converts it into a generic output
public protocol Analyzer {
  associatedtype Output

  /// Analyzes a Swift file and returns an StandardOutputConvertible output
  /// - Parameter fileURL: The fileURL where the Swift file is located
  func analyze(fileURL: URL) throws -> Output
}
