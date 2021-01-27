// Created by Dan Federman on 1/27/21.
//
// Copyright © 2021 Dan Federman
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

/// A struct that enables analyzing a Swift file at a URL with a Swift syntax visitor.
public struct StandardAnalyzer {

  /// - Parameter cachedSyntaxTree: The cached syntax tree to return the AST tree from
  public init(cachedSyntaxTree: CachedSyntaxTree = .init()) {
    self.cachedSyntaxTree = cachedSyntaxTree
  }

  /// Analyzes a Swift file with the provided visitor
  /// - Parameters:
  ///   - fileURL: The fileURL where the Swift file is located
  ///   - visitor: A Swift syntax visitor to use to analyze the provided file
  public func analyze<Visitor: SyntaxVisitor>(fileURL: URL, withVisitor visitor: Visitor) throws
  {
    let syntax: SourceFileSyntax = try cachedSyntaxTree.syntaxTree(for: fileURL)
    visitor.walk(syntax)
  }

  /// Analyzes a Swift file with the provide visitor
  /// - Parameters:
  ///   - fileURL: The fileURL where the Swift file is located
  ///   - visitor: A Swift syntax rewriter to use to analyze the provided file
  /// - Note: Use a visitor when possible. Rewriters should be used to work around this bug: https://bugs.swift.org/browse/SR-11591
  public func analyze<Visitor: SyntaxRewriter>(fileURL: URL, withVisitor visitor: Visitor) throws
  {
    let syntax: SourceFileSyntax = try cachedSyntaxTree.syntaxTree(for: fileURL)
    _ = visitor.visit(syntax)
  }

  // MARK: Private

  private let cachedSyntaxTree: CachedSyntaxTree

}
