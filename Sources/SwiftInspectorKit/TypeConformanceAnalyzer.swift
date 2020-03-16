// Created by Francisco Diaz on 10/14/19.
// Copyright © 2019 Airbnb Inc. All rights reserved.

import Foundation
import SwiftSyntax

public final class TypeConformanceAnalyzer: Analyzer {

  /// - Parameter typeName: The name of the type we're looking a type to conform to
  /// - Parameter cachedSyntaxTree: The cached syntax tree to return the AST tree from
  public init(typeName: String, cachedSyntaxTree: CachedSyntaxTree = .init()) {
    self.typeName = typeName
    self.cachedSyntaxTree = cachedSyntaxTree
  }

  /// Analyzes if the Swift file contains conformances to the typeName provided
  /// - Parameter fileURL: The fileURL where the Swift file is located
  public func analyze(fileURL: URL) throws -> TypeConformance {
    var doesConform = false

    let syntax: SourceFileSyntax = try cachedSyntaxTree.syntaxTree(for: fileURL)
    let reader = TypeConformanceSyntaxReader() { [unowned self] node in
      doesConform = doesConform || self.isSyntaxNode(node, ofType: self.typeName)
    }
    _ = reader.visit(syntax)

    return TypeConformance(typeName: typeName, doesConform: doesConform)
  }

  // MARK: Private

  private func isSyntaxNode(_ node: InheritedTypeSyntax, ofType typeName: String) -> Bool {
    // Remove leading and trailing whitespace trivia
    let syntaxTypeName = String(describing: node.typeName).trimmingCharacters(in: .whitespaces)
    return (syntaxTypeName == self.typeName)
  }
  
  private let typeName: String
  private let cachedSyntaxTree: CachedSyntaxTree
}

public struct TypeConformance: Equatable {
  public let typeName: String
  public let doesConform: Bool
}

// TODO: Update to use SyntaxVisitor when this bug is resolved (https://bugs.swift.org/browse/SR-11591)
private final class TypeConformanceSyntaxReader: SyntaxRewriter {
  init(onNodeVisit: @escaping (InheritedTypeSyntax) -> Void) {
    self.onNodeVisit = onNodeVisit
  }

  override func visit(_ node: InheritedTypeSyntax) -> Syntax {
    onNodeVisit(node)
    return super.visit(node)
  }

  private let onNodeVisit: (InheritedTypeSyntax) -> Void
}
