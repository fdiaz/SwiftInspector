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

// MARK: - TypeLocationAnalyzer

public final class TypeLocationAnalyzer: Analyzer {

  /// - Parameter typeName: The name of the type to locate.
  /// - Parameter cachedSyntaxTree: The cached syntax tree to return the AST tree from
  public init(typeName: String, cachedSyntaxTree: CachedSyntaxTree = .init()) {
    self.typeName = typeName
    self.cachedSyntaxTree = cachedSyntaxTree
  }

  /// Finds the location(s) of the specified type name in the Swift file
  /// - Parameter fileURL: The fileURL where the Swift file is located
  public func analyze(fileURL: URL) throws -> [LocatedType] {
    let syntax: SourceFileSyntax = try cachedSyntaxTree.syntaxTree(for: fileURL)
    var result = [LocatedType]()
    var visitor = TypeLocationSyntaxVisitor() { [unowned self] locatedType in
      guard self.typeName == locatedType.name else { return }
      result.append(locatedType)
    }
    syntax.walk(&visitor)
    return result
  }

  // MARK: Private

  private let cachedSyntaxTree: CachedSyntaxTree
  private let typeName: String
}

// MARK: - TypeLocationSyntaxVisitor

private final class TypeLocationSyntaxVisitor: SyntaxVisitor {

  init(onNodeVisit: @escaping (_ locatedType: LocatedType) -> Void) {
    self.onNodeVisit = onNodeVisit
  }

  func visit(_ node: ClassDeclSyntax) -> SyntaxVisitorContinueKind {
    processLocatedType(
      name: node.identifier.text,
      keywordToken: node.classKeyword,
      modifiers: node.modifiers,
      for: node)
    return .visitChildren
  }

  func visit(_ node: EnumDeclSyntax) -> SyntaxVisitorContinueKind {
    processLocatedType(
      name: node.identifier.text,
      keywordToken: node.enumKeyword,
      modifiers: node.modifiers,
      for: node)
    return .visitChildren
  }

  func visit(_ node: ProtocolDeclSyntax) -> SyntaxVisitorContinueKind {
    processLocatedType(
      name: node.identifier.text,
      keywordToken: node.protocolKeyword,
      modifiers: node.modifiers,
      for: node)
    return .visitChildren
  }

  func visit(_ node: StructDeclSyntax) -> SyntaxVisitorContinueKind {
    processLocatedType(
      name: node.identifier.text,
      keywordToken: node.structKeyword,
      modifiers: node.modifiers,
      for: node)
    return .visitChildren
  }

  func visit(_ token: TokenSyntax) -> SyntaxVisitorContinueKind {
    // Some nodes seem to include trivia from other nodes. Only counting newlines for trivia
    // associated with tokens ensures we get an accurate count.
    // Tokens are processed after `*DeclSyntax` nodes.
    if let leadingTrivia = token.leadingTrivia {
      currentLineNumber += leadingTrivia.countOfNewlines()
    }
    if let trailingTrivia = token.trailingTrivia {
      currentLineNumber += trailingTrivia.countOfNewlines()
    }
    return .visitChildren
  }

  private var currentLineNumber = 0
  private let onNodeVisit: (LocatedType) -> Void

  /// Compute the location of the type and invoke the callback.
  private func processLocatedType(
    name: String,
    keywordToken: TokenSyntax,
    modifiers: ModifierListSyntax?,
    for node: Syntax)
  {
    var indexOfStartingLine = currentLineNumber
    // We need to add this in early. We rely on the token visitation method to update
    // `currentLineNumber`.
    indexOfStartingLine += countOfLeadingNewlinesForType(
      keywordToken: keywordToken,
      modifiers: modifiers)

    let indexOfEndingLine = indexOfStartingLine + countOfNewlines(within: node)

    let locatedType = LocatedType(
      name: name,
      indexOfStartingLine: indexOfStartingLine,
      indexOfEndingLine: indexOfEndingLine)
    onNodeVisit(locatedType)
  }

  /// The number of newlines preceding this token.
  private func countOfLeadingNewlinesForType(
    keywordToken: TokenSyntax,
    modifiers: ModifierListSyntax?) -> Int
  {
    var result = 0
    result += keywordToken.leadingTrivia.countOfNewlines()
    modifiers?.leadingTrivia.flatMap { result += $0.countOfNewlines() }
    return result
  }

  /// Find the number of newlines within this node.
  private func countOfNewlines(within node: Syntax) -> Int {
    var countOfNewlinesInsideType = 0

    for (offset, token) in node.tokens.enumerated() {
      // We've already counted the leading trivia for the first token.
      if let leadingTrivia = token.leadingTrivia, offset != 0 {
        countOfNewlinesInsideType += leadingTrivia.countOfNewlines()
      }
      if let trailingTrivia = token.trailingTrivia{
        countOfNewlinesInsideType += trailingTrivia.countOfNewlines()
      }
    }

    return countOfNewlinesInsideType
  }
}

// MARK: - LocatedType

/// Information about a located type. Indices start with 0.
public struct LocatedType: Hashable {
  /// The name of the type.
  public let name: String
  /// The first line of the type.
  public let indexOfStartingLine: Int
  /// The last line of the type.
  public let indexOfEndingLine: Int
}

// MARK: Trivia

extension Trivia {

  fileprivate func countOfNewlines() -> Int {
    var result = 0
    for triviaPiece in self {
      switch triviaPiece {
      case .newlines(let count):
        result += count
      default:
        break
      }
    }
    return result
  }
}
