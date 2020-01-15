// Created by Francisco Diaz on 10/16/19.
// Copyright © 2019 Airbnb Inc. All rights reserved.

import Foundation
import SwiftSyntax

public final class StaticUsageAnalyzer: Analyzer {

  /// - Parameter singleton: The type and member names of the singleton we're looking
  /// - Parameter cachedSyntaxTree: The cached syntax tree from which to return the AST tree
  public init(singleton: StaticMember, cachedSyntaxTree: CachedSyntaxTree = .init()) {
    self.singleton = singleton
    self.cachedSyntaxTree = cachedSyntaxTree
  }

  /// Analyzes if the Swift file contains the singleton specified
  /// - Parameter fileURL: The fileURL where the Swift file is located
  public func analyze(fileURL: URL) throws -> StaticUsage {
    var isUsed = false
    let syntax: SourceFileSyntax = try cachedSyntaxTree.syntaxTree(for: fileURL)
    let reader = StaticUsageReader() { [unowned self] node in
      isUsed = isUsed || self.isSyntaxNode(node, ofType: self.singleton)
    }
    _ = reader.visit(syntax)

    return StaticUsage(singleton: self.singleton, fileName: fileURL.lastPathComponent, isUsed: isUsed)
  }

  // MARK: Private
  private func isSyntaxNode(_ node: MemberAccessExprSyntax, ofType singleton: StaticMember) -> Bool {
    // A MemberAccessExprSyntax contains a base, a dot and a name.
    // The base in this case will be the type of the singleton, while the name is the member

    let baseNode = node.base as? IdentifierExprSyntax
    let nameText = node.name.text
    guard let baseText = baseNode?.identifier.text else {
      return false
    }

    return baseText == singleton.typeName && nameText == singleton.memberName
  }

  private let singleton: StaticMember
  private let cachedSyntaxTree: CachedSyntaxTree
}

public struct StaticMember: Encodable, Equatable {
  public init(typeName: String, memberName: String) {
    self.typeName = typeName
    self.memberName = memberName
  }

  public let typeName: String
  public let memberName: String
}

public struct StaticUsage: Encodable, Equatable {
  let singleton: StaticMember
  let fileName: String
  let isUsed: Bool
}

// TODO: Update to use SyntaxVisitor when this bug is resolved (https://bugs.swift.org/browse/SR-11591)
private final class StaticUsageReader: SyntaxRewriter {
  init(onNodeVisit: @escaping (MemberAccessExprSyntax) -> Void) {
    self.onNodeVisit = onNodeVisit
  }

  override func visit(_ node: MemberAccessExprSyntax) -> ExprSyntax {
    onNodeVisit(node)
    return super.visit(node)
  }

  private let onNodeVisit: (MemberAccessExprSyntax) -> Void
}
