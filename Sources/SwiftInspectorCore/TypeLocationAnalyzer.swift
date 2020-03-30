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

  /// Analyzes the imports of the Swift file
  /// - Parameter fileURL: The fileURL where the Swift file is located
  public func analyze(fileURL: URL) throws -> LocatedType? {
    let syntax: SourceFileSyntax = try cachedSyntaxTree.syntaxTree(for: fileURL)
    var result: LocatedType?
    let reader = TypeLocationSyntaxReader() { [unowned self] locatedType in
      guard self.typeName == locatedType.name else { return }
      result = locatedType
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
    if let leadingTrivia = node.leadingTrivia {
      currentLineNumber += countOfNewlines(from: leadingTrivia, for: node)
    }

    var name: String?
    switch node {
    case let classDecl as ClassDeclSyntax:
      name = classDecl.identifier.text
    case let enumDecl as EnumDeclSyntax:
      name = enumDecl.identifier.text
    case let protocolDecl as ProtocolDeclSyntax:
      name = protocolDecl.identifier.text
    case let structDecl as StructDeclSyntax:
      name = structDecl.identifier.text
    default:
      break
    }

    if let name = name {
      let countOfNewlinesInsideType = countOfNewlines(within: node)
      let locatedType = LocatedType(
        name: name,
        indexOfStartingLine: currentLineNumber,
        indexOfEndingLine: currentLineNumber + countOfNewlinesInsideType)
      onNodeVisit(locatedType)
    }

    if let trailingTrivia = node.trailingTrivia {
      currentLineNumber += countOfNewlines(from: trailingTrivia, for: node)
    }

    return super.visitAny(node)
  }

  var currentLineNumber: UInt = 0
  let onNodeVisit: (LocatedType) -> Void

  private func countOfNewlines(from trivia: Trivia, for node: Syntax) -> UInt {
    // There may be a better way to do this. I found that CodeBlockItemSyntax was passing through
    // trivia from a child item, leading to incorrect counting. So I included all CodeBlock* items.
    if node is CodeBlockSyntax { return 0 }
    if node is CodeBlockItemSyntax { return 0 }
    if node is CodeBlockItemListSyntax { return 0 }
    return trivia.countOfNewlines()
  }

  /// Find the number of newlines within this node.
  private func countOfNewlines(within node: Syntax) -> UInt {
    var countOfNewlinesInsideType: UInt = 0

    for (offset, token) in node.tokens.enumerated() {
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
  public let indexOfStartingLine: UInt
  /// The last line of the type.
  public let indexOfEndingLine: UInt
}

// MARK: Trivia

extension Trivia {

  func countOfNewlines() -> UInt {
    var result: UInt = 0
    for triviaPiece in self {
      switch triviaPiece {
      case .newlines(let count):
        result += UInt(count)
      default:
        break
      }
    }
    return result
  }
}
