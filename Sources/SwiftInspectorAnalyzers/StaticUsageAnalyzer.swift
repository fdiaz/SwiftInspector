// Created by Francisco Diaz on 10/16/19.
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
    reader.walk(syntax)

    return StaticUsage(staticMember: self.staticMember, isUsed: isUsed)
  }

  // MARK: Private
  private func isSyntaxNode(_ node: MemberAccessExprSyntax, ofType staticMember: StaticMember) -> Bool {
    // A MemberAccessExprSyntax contains a base, a dot and a name.
    // The base in this case will be the type of the staticMember, while the name is the member

    let baseNode = node.base?.as(IdentifierExprSyntax.self)
    let nameText = node.name.text
    guard let baseText = baseNode?.identifier.text else {
      return false
    }

    return baseText == staticMember.typeName && nameText == staticMember.memberName
  }

  private let staticMember: StaticMember
  private let cachedSyntaxTree: CachedSyntaxTree
}

public struct StaticMember: Codable, Equatable {
  public init(typeName: String, memberName: String) {
    self.typeName = typeName
    self.memberName = memberName
  }

  public let typeName: String
  public let memberName: String
}

public struct StaticUsage: Equatable {
  public let staticMember: StaticMember
  public let isUsed: Bool
}

private final class StaticUsageReader: SyntaxVisitor {
  init(onNodeVisit: @escaping (MemberAccessExprSyntax) -> Void) {
    self.onNodeVisit = onNodeVisit
  }

  override func visit(_ node: MemberAccessExprSyntax) -> SyntaxVisitorContinueKind {
    onNodeVisit(node)
    return .visitChildren
  }

  private let onNodeVisit: (MemberAccessExprSyntax) -> Void
}
