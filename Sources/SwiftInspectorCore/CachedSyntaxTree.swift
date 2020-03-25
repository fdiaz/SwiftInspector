// Created by Francisco Diaz on 1/13/20.
//
// Copyright (c) 2020 Francisco Diaz
//
// Distributed under the MIT License
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

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
