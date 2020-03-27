// Created by Francisco Diaz on 3/25/20.
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

public final class TypealiasAnalyzer: Analyzer {

  /// - Parameter cachedSyntaxTree: The cached syntax tree to return the AST tree from
  public init(cachedSyntaxTree: CachedSyntaxTree = .init()) {
    self.cachedSyntaxTree = cachedSyntaxTree
  }

  /// Analyzes the imports of the Swift file
  /// - Parameter fileURL: The fileURL where the Swift file is located
  public func analyze(fileURL: URL) throws -> [TypealiasStatement] {
    let syntax: SourceFileSyntax = try cachedSyntaxTree.syntaxTree(for: fileURL)
    var allTypealias: [TypealiasStatement] = []
    let reader = TypealiasSyntaxReader() { [unowned self] node in
      let statement = self.typealiasStatement(from: node)
      allTypealias.append(statement)
    }
    _ = reader.visit(syntax)

    return allTypealias
  }

  // MARK: Private
  private let cachedSyntaxTree: CachedSyntaxTree

  private func typealiasStatement(from node: TypealiasDeclSyntax) -> TypealiasStatement {
    var identifiers: [String] = []

    for child in node.children {
      guard let typeInitializerSyntax = child as? TypeInitializerClauseSyntax else {
        continue
      }

      identifiers = findIdentifiers(from: typeInitializerSyntax)
    }

    return TypealiasStatement(name: node.identifier.text, identifiers:identifiers)
  }

  private func findIdentifiers(from node: TypeInitializerClauseSyntax) -> [String] {
    return node.tokens.reduce(into: []) { result, token in
      switch token.tokenKind {
      case .identifier(let name): result.append(name)
      default: return
      }
    }
  }
}

// TODO: Update to use SyntaxVisitor when this bug is resolved (https://bugs.swift.org/browse/SR-11591)
private final class TypealiasSyntaxReader: SyntaxRewriter {
  init(onNodeVisit: @escaping (TypealiasDeclSyntax) -> Void) {
    self.onNodeVisit = onNodeVisit
  }

  override func visit(_ node: TypealiasDeclSyntax) -> DeclSyntax {
    onNodeVisit(node)
    return super.visit(node)
  }

  let onNodeVisit: (TypealiasDeclSyntax) -> Void
}

public struct TypealiasStatement: Hashable {
  public let name: String
  public var identifiers: [String]
}
