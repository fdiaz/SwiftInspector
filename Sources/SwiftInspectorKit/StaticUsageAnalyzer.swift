// Created by Francisco Diaz on 10/16/19.
// Copyright © 2019 Airbnb Inc. All rights reserved.

import Foundation
import SwiftSyntax

public final class StaticUsageAnalyzer: Analyzer {

  /// - Parameter staticMember: The type and member names of the static member we're looking
  /// - Parameter cachedSyntaxTree: The cached syntax tree from which to return the AST tree
  public init(staticMember: StaticMember, cachedSyntaxTree: CachedSyntaxTree = .init()) {
    self.staticMember = staticMember
    self.cachedSyntaxTree = cachedSyntaxTree
  }

  /// Analyzes if the Swift file contains the static member specified
  /// - Parameter fileURL: The fileURL where the Swift file is located
  public func analyze(fileURL: URL) throws -> StaticUsage {
    var isUsed = false
    let syntax: SourceFileSyntax = try cachedSyntaxTree.syntaxTree(for: fileURL)
    let reader = StaticUsageReader() { [unowned self] node in
      isUsed = isUsed || self.isSyntaxNode(node, ofType: self.staticMember)
    }
    _ = reader.visit(syntax)

    return StaticUsage(staticMember: self.staticMember, fileName: fileURL.lastPathComponent, isUsed: isUsed)
  }

  // MARK: Private
  private func isSyntaxNode(_ node: MemberAccessExprSyntax, ofType staticMember: StaticMember) -> Bool {
    // A MemberAccessExprSyntax contains a base, a dot and a name.
    // The base in this case will be the type of the staticMember, while the name is the member

    let baseNode = node.base as? IdentifierExprSyntax
    let nameText = node.name.text
    guard let baseText = baseNode?.identifier.text else {
      return false
    }

    return baseText == staticMember.typeName && nameText == staticMember.memberName
  }

  private let staticMember: StaticMember
  private let cachedSyntaxTree: CachedSyntaxTree
}

public struct StaticMember: Equatable {
  public init(typeName: String, memberName: String) {
    self.typeName = typeName
    self.memberName = memberName
  }

  public let typeName: String
  public let memberName: String
}

public struct StaticUsage: Equatable, StandardOutputConvertible {
  public var standardOutput: String {
    "\(fileName) \(staticMember.typeName).\(staticMember.memberName) \(isUsed)"
  }

  let staticMember: StaticMember
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
