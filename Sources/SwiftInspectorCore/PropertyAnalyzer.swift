// Created by Tyler Hedrick on 8/14/20.
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

public final class PropertyAnalyzer: Analyzer {

  /// - Parameter typeName: The name of the type to get property information for
  /// - Parameter cachedSyntaxTree: The cached syntax tree to return the AST tree from
  public init(typeName: String, cachedSyntaxTree: CachedSyntaxTree = .init()) {
    self.typeName = typeName
    self.cachedSyntaxTree = cachedSyntaxTree
  }

  /// Finds the location(s) of the specified type name in the Swift file
  /// - Parameter fileURL: The fileURL where the Swift file is located
  public func analyze(fileURL: URL) throws -> TypeWithPropInfo? {
    let syntax: SourceFileSyntax = try cachedSyntaxTree.syntaxTree(for: fileURL)
    var result: TypeWithPropInfo?
    let visitor = TypeSyntaxVisitor() { [unowned self] typeWithPropInfo in
      guard self.typeName == typeWithPropInfo.name else { return }
      result = try? typeWithPropInfo.merge(with: result)
    }
    visitor.walk(syntax)
    return result
  }

  // MARK: Private

  private let cachedSyntaxTree: CachedSyntaxTree
  private let typeName: String
}

// MARK: - TypeLocationSyntaxVisitor

private final class TypeSyntaxVisitor: SyntaxVisitor {

  init(onNodeVisit: @escaping (_ info: TypeWithPropInfo) -> Void) {
    self.onNodeVisit = onNodeVisit
  }

  override func visit(_ node: ClassDeclSyntax) -> SyntaxVisitorContinueKind {
    processNode(node, withName: node.identifier.text, members: node.members.members)
    return .visitChildren
  }

  override func visit(_ node: EnumDeclSyntax) -> SyntaxVisitorContinueKind {
    processNode(node, withName: node.identifier.text, members: node.members.members)
    return .visitChildren
  }

  override func visit(_ node: ProtocolDeclSyntax) -> SyntaxVisitorContinueKind {
    processNode(node, withName: node.identifier.text, members: node.members.members)
    return .visitChildren
  }

  override func visit(_ node: StructDeclSyntax) -> SyntaxVisitorContinueKind {
    processNode(node, withName: node.identifier.text, members: node.members.members)
    return .visitChildren
  }

  override func visit(_ node: ExtensionDeclSyntax) -> SyntaxVisitorContinueKind {
    if let typeIdentifier = node.extendedType.as(SimpleTypeIdentifierSyntax.self) {
      processNode(node, withName: typeIdentifier.name.text, members: node.members.members)
    }
    return .visitChildren
  }

  // MARK: Private

  private let onNodeVisit: (_ info: TypeWithPropInfo) -> Void

  private func processNode<Node>(_ node: Node, withName name: String, members: MemberDeclListSyntax) where Node: SyntaxProtocol {
    var result = [TypeWithPropInfo.PropInfo]()
    let propertyVisitor = PropertySyntaxVisitor(parentName: name) { info in
      result.append(info)
    }
    propertyVisitor.walk(node)
    onNodeVisit(.init(name: name, properties: result))
  }
}

// MARK: - PropertySyntaxVisitor

private final class PropertySyntaxVisitor: SyntaxVisitor {

  init(parentName: String, onNodeVisit: @escaping (_ info: TypeWithPropInfo.PropInfo) -> Void) {
    self.parentName = parentName
    self.onNodeVisit = onNodeVisit
  }

  override func visit(_ node: VariableDeclSyntax) -> SyntaxVisitorContinueKind {
    var leadingTrivia: Trivia? = node.leadingTrivia
    var access: TypeWithPropInfo.Access = .internal
    var scope: TypeWithPropInfo.Scope = .instance

    node.modifiers?.forEach { modifier in
      // leading trivia is on the first modifier, or the node itself if no modifiers are present
      leadingTrivia = leadingTrivia ?? modifier.leadingTrivia
      // This attempts to get any access information from the node's modifiers
      if let modifierAccess = TypeWithPropInfo.Access(rawValue: modifier.name.text) {
        access = modifierAccess
      }
      // this attempts to get any scope information from the node's modifiers
      if let modifierScope = TypeWithPropInfo.Scope(rawValue: modifier.name.text) {
        scope = modifierScope
      }
    }

    // in practice this `bindings` array only has 1 element
    node.bindings.forEach { binding in
      if let identifier = binding.pattern.as(IdentifierPatternSyntax.self) {
        if
          let typeAnnotation = binding.typeAnnotation,
          let simpleTypeIdentifier = typeAnnotation.type.as(SimpleTypeIdentifierSyntax.self)
        {
          onNodeVisit(.init(
            name: identifier.identifier.text,
            typeAnnotation: simpleTypeIdentifier.name.text,
            comment: comment(from: leadingTrivia),
            access: access,
            scope: scope))
          return
        }
        // no type annotation was found. In this case it's much more complicated to get
        // the type information for a variable.
        // TODO: Include logic to get types of any variable declaration
        onNodeVisit(.init(
          name: identifier.identifier.text,
          typeAnnotation: nil,
          comment: comment(from: leadingTrivia),
          access: access,
          scope: scope))
      }
    }

    return .skipChildren
  }

  // MARK: Private

  private let parentName: String
  private let onNodeVisit: (_ info: TypeWithPropInfo.PropInfo) -> Void

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

// MARK: - TypeWithPropInfo

/// Information about a located type. Indices start with 0.
public struct TypeWithPropInfo: Hashable {

  public enum Access: String {
    case `public`
    case `internal`
    case `private`
    case `fileprivate`
  }

  public enum Scope: String {
    case instance
    case `static`
  }

  public struct PropInfo: Hashable {
    /// The name of the property
    public let name: String
    /// The Type annotation of the property if it's present
    public let typeAnnotation: String?
    /// Any comments associated with the property
    public let comment: String
    /// Access control of this property
    public let access: Access
    /// Scope of this property
    public let scope: Scope
  }

  /// The name of the type.
  public let name: String
  /// The properites on this type
  public let properties: [PropInfo]
}

extension TypeWithPropInfo {
  struct MergeError: Error, CustomStringConvertible {

    init(errorMessage: String) {
      self.errorMessage = errorMessage
    }

    var description: String { errorMessage }

    private let errorMessage: String
  }
}

extension TypeWithPropInfo.MergeError {
  static var invalidNames = TypeWithPropInfo.MergeError(
    errorMessage: "Invalid types - the type names must match to be merged.")
}

extension TypeWithPropInfo {
  func merge(with other: TypeWithPropInfo?) throws -> TypeWithPropInfo {
    guard let other = other else {
      return self
    }
    guard name == other.name else {
      throw MergeError.invalidNames
      return self
    }
    return TypeWithPropInfo(
      name: name,
      properties: Array(Set(properties).union(Set(other.properties))))
  }
}
