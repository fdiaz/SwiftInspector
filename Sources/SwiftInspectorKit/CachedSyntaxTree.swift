// Created by Francisco Diaz on 1/13/20.
// Copyright © 2020 Airbnb Inc. All rights reserved.

import Foundation
import SwiftSyntax

/// A type that knows how to return a source file syntax given a file URL
public final class CachedSyntaxTree {
  public init() {
    cachedSyntax = [:]
  }

  /// Returns a memoized `SourceFileSyntax` tree if it exists, otherwise calculates, memoizes, and returns the syntax tree of the file URL
  /// 
  /// - Parameter fileURL: The location of the Swift file to parse
  ///
  /// - Warning: This method is not thread-safe
  func syntaxTree(for fileURL: URL) throws -> SourceFileSyntax {
    guard let syntax = cachedSyntax[fileURL] else {
      return try memoizeSyntaxTree(at: fileURL)
    }
    return syntax
  }

  /// It reads the `SourceFileSyntax` at the file URL location and parses it into a `SourceFileSyntax, then it caches the result in memory
  /// 
  /// - Parameter fileURL: The location of the Swift file to parse
  private func memoizeSyntaxTree(at fileURL: URL) throws -> SourceFileSyntax {
    let cached =  try SyntaxParser.parse(fileURL)
    cachedSyntax[fileURL] = cached
    return cached
  }

  private var cachedSyntax: [URL: SourceFileSyntax]
}
