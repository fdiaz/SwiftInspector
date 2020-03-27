// Created by Francisco Diaz on 3/27/20.
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

public final class InitializerAnalyzer: Analyzer {
  /// - Parameter cachedSyntaxTree: The cached syntax tree to return the AST tree from
  public init(name: String, cachedSyntaxTree: CachedSyntaxTree = .init()) {
    self.name = name
    self.cachedSyntaxTree = cachedSyntaxTree
  }

  public func analyze(fileURL: URL) throws -> [InitializerStatement] {
    var statements: [InitializerStatement] = []
    let syntax = try cachedSyntaxTree.syntaxTree(for: fileURL)

    var reader = InitializerSyntaxReader(shouldVisitIdentifier: shouldVisit) { [unowned self] node in
      let statement = self.initializerStatement(from: node)
      statements.append(statement)
    }
    syntax.walk(&reader)

    return statements
  }

  // MARK: Private
  private let name: String
  private let cachedSyntaxTree: CachedSyntaxTree

  private func shouldVisit(_ identifier: String) -> Bool {
    identifier == name
  }

  private func initializerStatement(from node: InitializerDeclSyntax) -> InitializerStatement {
    let parameters = findParameters(from: node)
    let modifiers = findModifiers(from: node)
    return InitializerStatement(typeName: name, parameters: parameters, modifiers: modifiers)
  }

  private func findParameters(from node: InitializerDeclSyntax) -> [InitializerStatement.Parameter] {
    let functionList = node.children
      .compactMap { $0 as? ParameterClauseSyntax }
      .first?.children
      .compactMap { $0 as? FunctionParameterListSyntax }
      .first

    guard let list = functionList else {
      return []
    }

    var parameters: [InitializerStatement.Parameter] = []

    for parameterNode in list {
      let parameter = findParameter(from: parameterNode)
      parameters.append(parameter)
    }

    return parameters
  }

  private func findParameter(from node: FunctionParameterSyntax) -> InitializerStatement.Parameter {
    let name = node.firstName?.text ?? ""
    let typeName = node.children.compactMap { $0 as? SimpleTypeIdentifierSyntax }.first?.name.text ?? ""

    return .init(name: name, typeName: typeName)
  }

  private func findModifiers(from node: InitializerDeclSyntax) -> InitializerStatement.Modifier {
    let modifiersString: [String] = node.children
      .compactMap { $0 as? ModifierListSyntax }
      .reduce(into: []) { result, syntax in
        let modifiers = syntax.children
          .compactMap { $0 as? DeclModifierSyntax }
          .map { $0.name.text }
        result.append(contentsOf: modifiers)
      }

    var modifier = modifiersString.reduce(InitializerStatement.Modifier()) { result, stringValue in
      let modifier = InitializerStatement.Modifier(stringValue: stringValue)
      return result.union(modifier)
    }

    // If there are no explicit modifiers, this is a designated initializer
    guard !modifier.isEmpty else {
      return .designated
    }

    // If an initializer is not a convenience initializer, it's a designated initializer
    if !modifier.contains(.convenience) {
      modifier = modifier.union(.designated)
    }

    return modifier
  }
}

public struct InitializerStatement: Equatable {
  public let typeName: String
  public let parameters: [Parameter]
  public let modifiers: Modifier


  public struct Parameter: Equatable {
    let name: String
    let typeName: String
  }

  public struct Modifier: Equatable, OptionSet  {
    public let rawValue: Int

    public static let designated = Modifier(rawValue: 1 << 0)
    public static let convenience = Modifier(rawValue: 1 << 1)
    public static let override = Modifier(rawValue: 1 << 2)
    public static let required = Modifier(rawValue: 1 << 3)

    public init(rawValue: Int)  {
      self.rawValue = rawValue
    }

    public init(stringValue: String) {
      switch stringValue {
      case "convenience": self = .convenience
      case "override": self = .override
      case "required": self = .required
      default: self = []
      }
    }
  }
}

private final class InitializerSyntaxReader: SyntaxVisitor {
  init(
    shouldVisitIdentifier: @escaping (String) -> Bool,
    onNodeVisit: @escaping (InitializerDeclSyntax) -> Void
  )
  {
    self.shouldVisitIdentifier = shouldVisitIdentifier
    self.onNodeVisit = onNodeVisit
  }

  func visit(_ node: ClassDeclSyntax) -> SyntaxVisitorContinueKind {
    shouldVisitIdentifier(node.identifier.text) ? .visitChildren : .skipChildren
  }

  func visit(_ node: StructDeclSyntax) -> SyntaxVisitorContinueKind {
    shouldVisitIdentifier(node.identifier.text) ? .visitChildren : .skipChildren
  }

  func visit(_ node: EnumDeclSyntax) -> SyntaxVisitorContinueKind {
    shouldVisitIdentifier(node.identifier.text) ? .visitChildren : .skipChildren
  }

  func visit(_ node: InitializerDeclSyntax) -> SyntaxVisitorContinueKind {
    onNodeVisit(node)
    return .visitChildren
  }

  let shouldVisitIdentifier: (String) -> Bool
  let onNodeVisit: (InitializerDeclSyntax) -> Void
}
