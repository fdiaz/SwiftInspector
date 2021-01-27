// Created by Francisco Diaz on 10/14/19.
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
    var conformingTypes: [String] = []

    let syntax: SourceFileSyntax = try cachedSyntaxTree.syntaxTree(for: fileURL)
    let reader = TypeConformanceSyntaxVisitor() { [unowned self] node in
      let nodeConforms = self.isSyntaxNode(node, ofType: self.typeName)
      guard nodeConforms else { return }
      doesConform = doesConform || nodeConforms

      guard let node = self.findConformingType(of: node) else { return }
      conformingTypes.append(node)
    }

    reader.walk(syntax)

    return TypeConformance(typeName: typeName, doesConform: doesConform, conformingTypeNames: conformingTypes)
  }

  // MARK: Private

  private func isSyntaxNode(_ node: InheritedTypeSyntax, ofType typeName: String) -> Bool {
    // Remove leading and trailing whitespace trivia
    let syntaxTypeName = String(describing: node.typeName).trimmingCharacters(in: .whitespaces)
    return (syntaxTypeName == self.typeName)
  }

  private func findConformingType(of node: SyntaxProtocol?) -> String? {
    guard let originalNode = node else { return nil }

    guard let parent = originalNode.parent else { return nil }

    // A conforming type can only be a class, struct or enum
    // See: https://docs.swift.org/swift-book/LanguageGuide/Protocols.html
    if let classSyntax = parent.as(ClassDeclSyntax.self) {
      return classSyntax.identifier.text
    } else if let structSyntax = parent.as(StructDeclSyntax.self) {
      return structSyntax.identifier.text
    } else if let enumSyntax = parent.as(EnumDeclSyntax.self) {
      return enumSyntax.identifier.text
    } else {
      return findConformingType(of: parent.parent)
    }
  }
  
  private let typeName: String
  private let cachedSyntaxTree: CachedSyntaxTree
}

public struct TypeConformance: Equatable {
  public let typeName: String
  public let doesConform: Bool
  public let conformingTypeNames: [String]
}

private final class TypeConformanceSyntaxVisitor: SyntaxVisitor {
  init(onNodeVisit: @escaping (InheritedTypeSyntax) -> Void) {
    self.onNodeVisit = onNodeVisit
  }

  override func visit(_ node: InheritedTypeSyntax) -> SyntaxVisitorContinueKind {
    onNodeVisit(node)
    return .visitChildren
  }

  private let onNodeVisit: (InheritedTypeSyntax) -> Void
}
