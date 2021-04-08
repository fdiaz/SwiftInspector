// Created by Tyler Hedrick on 8/14/20.
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
import SwiftInspectorVisitors
import SwiftSyntax

// MARK: - PropertyAnalyzer

public final class PropertyAnalyzer: Analyzer {

  /// - Parameter typeName: The name of the type to get property information for
  /// - Parameter cachedSyntaxTree: The cached syntax tree to return the AST tree from
  public init(typeName: String, cachedSyntaxTree: CachedSyntaxTree = .init()) {
    self.typeName = typeName
    self.cachedSyntaxTree = cachedSyntaxTree
  }

  /// Finds property information for the provided type in the Swift file
  /// - Parameter fileURL: The fileURL where the Swift file is located
  public func analyze(fileURL: URL) throws -> Set<PropertyData>? {
    let syntax: SourceFileSyntax = try cachedSyntaxTree.syntaxTree(for: fileURL)
    let visitor = TypeSyntaxVisitor(typeName: typeName)
    visitor.walk(syntax)
    return visitor.propertiesData
  }

  // MARK: Private

  private let cachedSyntaxTree: CachedSyntaxTree
  private let typeName: String
}
