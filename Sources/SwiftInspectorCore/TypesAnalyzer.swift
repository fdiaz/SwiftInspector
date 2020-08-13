// Created by Tyler Hedrick on 8/12/20.
//
// Copyright (c) 2020 Tyler Hedrick
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

public final class TypesAnalyzer: Analyzer {

  /// - Parameter cachedSyntaxTree: The cached syntax tree to return the AST tree from
  public init(cachedSyntaxTree: CachedSyntaxTree = .init()) {
    self.cachedSyntaxTree = cachedSyntaxTree
  }

  /// Analyzes the types located in the provided file
  /// - Parameter fileURL: The fileURL where the Swift file is located
  public func analyze(fileURL: URL) throws -> [TypeInfo] {
    let syntax: SourceFileSyntax = try cachedSyntaxTree.syntaxTree(for: fileURL)
    var result = [TypeInfo]()
    let visitor = TypeInfoSyntaxVisitor() { typeInfo in
      result.append(typeInfo)
    }
    visitor.walk(syntax)
    return result
  }

  // MARK: Private

  private let cachedSyntaxTree: CachedSyntaxTree
}

private final class TypeInfoSyntaxVisitor: SyntaxVisitor {
  init(_ onNodeVisit: @escaping (TypeInfo) -> Void) {
    self.onNodeVisit = onNodeVisit
  }

  override func visit(_ node: ClassDeclSyntax) -> SyntaxVisitorContinueKind {
    onNodeVisit(.init(
      type: .class,
      name: node.identifier.text,
      comment: comment(from: node.leadingTrivia)))
    return .visitChildren
  }

  override func visit(_ node: EnumDeclSyntax) -> SyntaxVisitorContinueKind {
    onNodeVisit(.init(
      type: .enum,
      name: node.identifier.text,
      comment: comment(from: node.leadingTrivia)))
    return .visitChildren
  }

  override func visit(_ node: ProtocolDeclSyntax) -> SyntaxVisitorContinueKind {
    onNodeVisit(.init(
      type: .protocol,
      name: node.identifier.text,
      comment: comment(from: node.leadingTrivia)))
    return .visitChildren
  }

  override func visit(_ node: StructDeclSyntax) -> SyntaxVisitorContinueKind {
    onNodeVisit(.init(
      type: .struct,
      name: node.identifier.text,
      comment: comment(from: node.leadingTrivia)))
    return .visitChildren
  }

  // MARK: Private

  private let onNodeVisit: (TypeInfo) -> Void

  private func comment(from trivia: Trivia?) -> String {
    guard let trivia = trivia else { return "" }
    return trivia.compactMap { piece -> String? in
      switch piece {
      case .lineComment(let str): return str
      case .blockComment(let str): return str
      case .docLineComment(let str): return str
      case .docBlockComment(let str): return str
      default: return nil
      }
    }.joined(separator: "\n")
  }
}

// MARK: TypeInfo

public struct TypeInfo {
  public enum SwiftType: String {
    case `class`
    case `struct`
    case `protocol`
    case `enum`
  }

  /// Swift type name (class, struct, protocol, or enum)
  public let type: SwiftType
  /// The name of the type
  public let name: String
  /// Comments associated with this type (leadingTrivia from SwiftSyntax)
  public let comment: String
}
