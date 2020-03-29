// Created by Michael Bachand on 3/28/20.
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

public final class TypeLocationAnalyzer: Analyzer {

  /// - Parameter typeName: The name of the type to locate.
  /// - Parameter cachedSyntaxTree: The cached syntax tree to return the AST tree from
  public init(typeName: String, cachedSyntaxTree: CachedSyntaxTree = .init()) {
    self.typeName = typeName
    self.cachedSyntaxTree = cachedSyntaxTree
  }

  /// Analyzes the imports of the Swift file
  /// - Parameter fileURL: The fileURL where the Swift file is located
  public func analyze(fileURL: URL) throws -> TypeLocation? {
    let syntax: SourceFileSyntax = try cachedSyntaxTree.syntaxTree(for: fileURL)
    var typeLocation: TypeLocation?
    let reader = TypeLocationSyntaxReader() { [unowned self] typeName in
      guard self.typeName == typeName else { return }
      typeLocation = TypeLocation(indexOfStartingLine: 0, indexOfEndingLine: 0)
    }
    _ = reader.visit(syntax)

    return typeLocation
  }

  // MARK: Private

  private let cachedSyntaxTree: CachedSyntaxTree
  private let typeName: String
}

// TODO: Update to use SyntaxVisitor when this bug is resolved (https://bugs.swift.org/browse/SR-11591)
private final class TypeLocationSyntaxReader: SyntaxRewriter {
  init(onNodeVisit: @escaping (_ typeName: String) -> Void) {
    self.onNodeVisit = onNodeVisit
  }

  override func visit(_ node: ClassDeclSyntax) -> DeclSyntax {
    onNodeVisit(node.identifier.text)
    return super.visit(node)
  }

  override func visit(_ node: EnumDeclSyntax) -> DeclSyntax {
    onNodeVisit(node.identifier.text)
    return super.visit(node)
  }

  override func visit(_ node: ProtocolDeclSyntax) -> DeclSyntax {
    onNodeVisit(node.identifier.text)
    return super.visit(node)
  }

  override func visit(_ node: StructDeclSyntax) -> DeclSyntax {
    onNodeVisit(node.identifier.text)
    return super.visit(node)
  }

  let onNodeVisit: (String) -> Void
}

/// Information about a located type. Indices start with 0.
public struct TypeLocation: Hashable {
  /// The first line of the type.
  public let indexOfStartingLine: UInt
  /// The last line of the type.
  public let indexOfEndingLine: UInt
}
