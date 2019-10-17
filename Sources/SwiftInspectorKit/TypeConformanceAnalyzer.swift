// Created by Francisco Diaz on 10/14/19.
// Copyright © 2019 Airbnb Inc. All rights reserved.

import Foundation
import SwiftSyntax

public final class TypeConformanceAnalyzer {

  /// - Parameter typeName: The name of the type we're looking a type to conform to
  public init(typeName: String) {
    self.typeName = typeName
  }

  /// Analyzes if the Swift file contains conformances to the typeName provided
  /// - Parameter fileURL: The fileURL where the Swift file is located
  public func analyze(fileURL: URL) throws -> TypeConformance {
    var doesConform = false

    let syntax: SourceFileSyntax = try SyntaxParser.parse(fileURL)
    let reader = TypeConformanceSyntaxReader() { [unowned self] node in
      doesConform = doesConform || self.isSyntaxNode(node, ofType: self.typeName)
    }
    _ = reader.visit(syntax)

    return TypeConformance(typeName: typeName, fileName: fileURL.lastPathComponent, doesConform: doesConform)
  }

  // MARK: Private

  private func isSyntaxNode(_ node: InheritedTypeSyntax, ofType typeName: String) -> Bool {
    // Remove leading and trailing whitespace trivia
    let syntaxTypeName = String(describing: node.typeName).trimmingCharacters(in: .whitespaces)
    return (syntaxTypeName == self.typeName)
  }
  
  private let typeName: String
}

public struct TypeConformance: Equatable {
  let typeName: String
  let fileName: String
  let doesConform: Bool
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
