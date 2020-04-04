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
    let reader = TypeLocationSyntaxReader() { [unowned self] locatedType in
      guard self.typeName == locatedType.name else { return }
      result.append(locatedType)
    }
    _ = reader.visit(syntax)

    return result
  }

  // MARK: Private

  private let cachedSyntaxTree: CachedSyntaxTree
  private let typeName: String
}

// TODO: Update to use SyntaxVisitor when this bug is resolved (https://bugs.swift.org/browse/SR-11591)
private final class TypeLocationSyntaxReader: SyntaxRewriter {
  init(onNodeVisit: @escaping (_ locatedType: LocatedType) -> Void) {
    self.onNodeVisit = onNodeVisit
  }

  override func visitAny(_ node: Syntax) -> Syntax? {
    let anyLocatedType: (name: String, keywordToken: TokenSyntax, modifiers: ModifierListSyntax?)?

    switch node {
    case let classDecl as ClassDeclSyntax:
      anyLocatedType = (classDecl.identifier.text, classDecl.classKeyword, classDecl.modifiers)
    case let enumDecl as EnumDeclSyntax:
      anyLocatedType = (enumDecl.identifier.text, enumDecl.enumKeyword, enumDecl.modifiers)
    case let protocolDecl as ProtocolDeclSyntax:
      anyLocatedType = (protocolDecl.identifier.text, protocolDecl.protocolKeyword, protocolDecl.modifiers)
    case let structDecl as StructDeclSyntax:
      anyLocatedType = (structDecl.identifier.text, structDecl.structKeyword, structDecl.modifiers)
    default:
      anyLocatedType = nil
    }

    if let anyLocatedType = anyLocatedType {
      var indexOfStartingLine = currentLineNumber
      // We need to add this in early. We don't modify currentLineNumber since they will be added
      // in later when we compute the leading newlines for this entire node.
      indexOfStartingLine += countOfLeadingNewlinesForType(
        keywordToken: anyLocatedType.keywordToken,
        modifiers: anyLocatedType.modifiers)

      let indexOfEndingLine = indexOfStartingLine + countOfNewlines(within: node)

      let locatedType = LocatedType(
        name: anyLocatedType.name,
        indexOfStartingLine: indexOfStartingLine,
        indexOfEndingLine: indexOfEndingLine)
      onNodeVisit(locatedType)
    }

    if let leadingTrivia = node.leadingTrivia {
      currentLineNumber += countOfNewlines(from: leadingTrivia, for: node)
    }
    if let trailingTrivia = node.trailingTrivia {
      currentLineNumber += countOfNewlines(from: trailingTrivia, for: node)
    }

    return super.visitAny(node)
  }

  var currentLineNumber = 0
  let onNodeVisit: (LocatedType) -> Void

  /// The total newlines associated with this node.
  private func countOfNewlines(from trivia: Trivia, for node: Syntax) -> Int {
    // Some nodes seem to include trivia from other nodes. Filtering to just tokens ensures we get
    // an accurate count.
    guard node is TokenSyntax else { return 0 }
    return trivia.countOfNewlines()
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
