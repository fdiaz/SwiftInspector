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
import SwiftInspectorVisitors
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

    let reader = InitializerSyntaxReader(shouldVisitIdentifier: shouldVisit) { [unowned self] node in
      let statement = self.initializerStatement(from: node)
      statements.append(statement)
    }
    reader.walk(syntax)

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
      .compactMap { $0.as(ParameterClauseSyntax.self) }
      .first?.children
      .compactMap { $0.as(FunctionParameterListSyntax.self) }
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
    let name: String
    // If the initializer contains a different parameter and an argument label we want to check first
    // for the parameter. e.g. init(some another: String) -- the parameter would be `another`
    if let secondName = node.secondName {
      name = secondName.text
    } else if let firstName = node.firstName {
      name = firstName.text
    } else {
      name = ""
    }

    var typeNames: [String] = []
    let reader = FunctionParameterReader() { identifierNode in
      typeNames.append(identifierNode.name.text)
    }
    reader.walk(node)

    return .init(name: name, typeNames: typeNames)
  }

  private func findModifiers(from node: InitializerDeclSyntax) -> Modifiers {
    let modifiersString: [String] = node.children
      .compactMap { $0.as(ModifierListSyntax.self) }
      .reduce(into: []) { result, syntax in
        let modifiers = syntax.children
          .compactMap { $0.as(DeclModifierSyntax.self) }
          .map { $0.name.text }
        result.append(contentsOf: modifiers)
      }

    var modifier = modifiersString.reduce(Modifiers()) { result, stringValue in
      let modifier = Modifiers(stringValue: stringValue)
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
  public let modifiers: Modifiers


  public struct Parameter: Equatable {
    public let name: String
    public let typeNames: [String]

    /// The most common use case is for a parameter to only contain one type
    /// That's why we have this computed property as a convenience
    public var typeName: String? {
      return typeNames.first
    }

    public init(name: String, typeNames: [String]) {
      self.name = name
      self.typeNames = typeNames
    }

    /// The most common use case is for a parameter to only contain one type
    /// That's why we have this convenience initializer
    public init(name: String, typeName: String) {
      self.name = name
      self.typeNames = [typeName]
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

  override func visit(_ node: ClassDeclSyntax) -> SyntaxVisitorContinueKind {
    shouldVisitIdentifier(node.identifier.text) ? .visitChildren : .skipChildren
  }

  override func visit(_ node: StructDeclSyntax) -> SyntaxVisitorContinueKind {
    shouldVisitIdentifier(node.identifier.text) ? .visitChildren : .skipChildren
  }

  override func visit(_ node: EnumDeclSyntax) -> SyntaxVisitorContinueKind {
    shouldVisitIdentifier(node.identifier.text) ? .visitChildren : .skipChildren
  }

  override func visit(_ node: InitializerDeclSyntax) -> SyntaxVisitorContinueKind {
    onNodeVisit(node)
    return .visitChildren
  }

  let shouldVisitIdentifier: (String) -> Bool
  let onNodeVisit: (InitializerDeclSyntax) -> Void
}

private final class FunctionParameterReader: SyntaxVisitor {
  init(onNodeVisit: @escaping (SimpleTypeIdentifierSyntax) -> Void) {
    self.onNodeVisit = onNodeVisit
  }

  override func visit(_ node: SimpleTypeIdentifierSyntax) -> SyntaxVisitorContinueKind {
    onNodeVisit(node)
    return .visitChildren
  }

  let onNodeVisit: (SimpleTypeIdentifierSyntax) -> Void

}
