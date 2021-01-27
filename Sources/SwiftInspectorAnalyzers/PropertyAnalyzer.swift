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

// MARK: - PropertyAnalyzer

public final class PropertyAnalyzer: Analyzer {

  /// - Parameter typeName: The name of the type to get property information for
  /// - Parameter cachedSyntaxTree: The cached syntax tree to return the AST tree from
  public init(typeName: String, cachedSyntaxTree: CachedSyntaxTree = .init()) {
    self.typeName = typeName
    self.cachedSyntaxTree = cachedSyntaxTree
  }

  /// Finds property information for the provided type in the Swift file
  /// - Parameter fileURL: The fileURL where the Swift file is located
  public func analyze(fileURL: URL) throws -> TypeProperties? {
    let syntax: SourceFileSyntax = try cachedSyntaxTree.syntaxTree(for: fileURL)
    var result: TypeProperties?
    let visitor = TypeSyntaxVisitor(typeName: typeName) { [unowned self] typeProperties in
      guard self.typeName == typeProperties.name else { return }
      result = try? typeProperties.merge(with: result)
    }
    visitor.walk(syntax)
    return result
  }

  // MARK: Private

  private let cachedSyntaxTree: CachedSyntaxTree
  private let typeName: String
}

// MARK: - TypeSyntaxVisitor

private final class TypeSyntaxVisitor: SyntaxVisitor {

  init(typeName: String, onNodeVisit: @escaping (_ info: TypeProperties) -> Void) {
    self.onNodeVisit = onNodeVisit
    self.typeName = typeName
  }

  override func visit(_ node: ClassDeclSyntax) -> SyntaxVisitorContinueKind {
    if node.identifier.text == typeName {
      processNode(node, withName: node.identifier.text, members: node.members.members)
    }
    return .visitChildren
  }

  override func visit(_ node: EnumDeclSyntax) -> SyntaxVisitorContinueKind {
    if node.identifier.text == typeName {
      processNode(node, withName: node.identifier.text, members: node.members.members)
    }
    return .visitChildren
  }

  override func visit(_ node: ProtocolDeclSyntax) -> SyntaxVisitorContinueKind {
    if node.identifier.text == typeName {
      processNode(node, withName: node.identifier.text, members: node.members.members)
    }
    return .visitChildren
  }

  override func visit(_ node: StructDeclSyntax) -> SyntaxVisitorContinueKind {
    if node.identifier.text == typeName {
      processNode(node, withName: node.identifier.text, members: node.members.members)
    }
    return .visitChildren
  }

  override func visit(_ node: ExtensionDeclSyntax) -> SyntaxVisitorContinueKind {
    if
      let typeIdentifier = node.extendedType.as(SimpleTypeIdentifierSyntax.self),
      typeIdentifier.name.text == typeName
    {
      processNode(node, withName: typeIdentifier.name.text, members: node.members.members)
    }
    return .visitChildren
  }

  // MARK: Private

  private let onNodeVisit: (_ info: TypeProperties) -> Void
  private let typeName: String

  private func processNode<Node>(_ node: Node, withName name: String, members: MemberDeclListSyntax) where Node: SyntaxProtocol {
    var result = [TypeProperties.PropertyData]()
    let propertyVisitor = PropertySyntaxVisitor(typeName: name) { info in
      result.append(info)
    }
    propertyVisitor.walk(node)
    onNodeVisit(.init(name: name, properties: result))
  }
}

// MARK: - PropertySyntaxVisitor

private final class PropertySyntaxVisitor: SyntaxVisitor {

  init(typeName: String, onNodeVisit: @escaping (_ info: TypeProperties.PropertyData) -> Void) {
    self.typeName = typeName
    self.onNodeVisit = onNodeVisit
  }

  override func visit(_ node: VariableDeclSyntax) -> SyntaxVisitorContinueKind {
    var leadingTrivia: Trivia? = node.leadingTrivia
    let modifier = findModifiers(from: node)

    node.modifiers?.forEach { modifier in
      // leading trivia is on the first modifier, or the node itself if no modifiers are present
      leadingTrivia = leadingTrivia ?? modifier.leadingTrivia
    }

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
            modifiers: modifier))
          return
        }
        // no type annotation was found. In this case it's much more complicated to get
        // the type information for a variable.
        // e.g.:
        // public let thing: String = "Hello" has a type annotation, String which makes this easy
        // public let thing = "Hello" does not have a type annotation, and I don't know how to handle this case.
        // TODO: Include logic to get types of any variable declaration
        onNodeVisit(.init(
          name: identifier.identifier.text,
          typeAnnotation: nil,
          comment: comment(from: leadingTrivia),
          modifiers: modifier))
      }
    }

    return .skipChildren
  }

  // MARK: Private

  private let typeName: String
  private let onNodeVisit: (_ info: TypeProperties.PropertyData) -> Void

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

  private func findModifiers(from node: VariableDeclSyntax) -> TypeProperties.Modifier {
    let modifiersString: [String] = node.children
      .compactMap { $0.as(ModifierListSyntax.self) }
      .reduce(into: []) { result, syntax in
        let modifiers: [String] = syntax.children
          .compactMap { $0.as(DeclModifierSyntax.self) }
          .map { modifierSyntax in
            if
              let leftParen = modifierSyntax.detailLeftParen,
              let detail = modifierSyntax.detail,
              let rightParen = modifierSyntax.detailRightParen
            {
              return modifierSyntax.name.text + leftParen.text + detail.text + rightParen.text
            }
            return modifierSyntax.name.text
        }
        result.append(contentsOf: modifiers)
      }

    var modifier = modifiersString.reduce(TypeProperties.Modifier()) { result, stringValue in
      let modifier = TypeProperties.Modifier(stringValue: stringValue)
      return result.union(modifier)
    }

    // If there are no explicit modifiers, this is an internal property
    if !modifier.contains(.public) &&
      !modifier.contains(.fileprivate) &&
      !modifier.contains(.private)
    {
      modifier = modifier.union(.internal)
    }

    // If the variable isn't static, it's an instance variable
    if !modifier.contains(.static) {
      modifier = modifier.union(.instance)
    }

    return modifier
  }
}

// MARK: - TypeProperties

/// Information about a type as well as its associated properties
public struct TypeProperties: Hashable {

  public struct Modifier: Hashable, OptionSet {
    public let rawValue: Int

    // general accessors
    public static let `internal` = Modifier(rawValue: 1 << 0)
    public static let `public` = Modifier(rawValue: 1 << 1)
    public static let `private` = Modifier(rawValue: 1 << 2)
    public static let `fileprivate` = Modifier(rawValue: 1 << 3)
    // set accessors
    public static let privateSet = Modifier(rawValue: 1 << 4)
    public static let internalSet = Modifier(rawValue: 1 << 5)
    public static let publicSet = Modifier(rawValue: 1 << 6)
    // access control
    public static let `instance` = Modifier(rawValue: 1 << 7)
    public static let `static` = Modifier(rawValue: 1 << 8)

    public init(rawValue: Int)  {
      self.rawValue = rawValue
    }

    public init(stringValue: String) {
      switch stringValue {
      case "public": self = .public
      case "private": self = .private
      case "fileprivate": self = .fileprivate
      case "private(set)": self = .privateSet
      case "internal(set)": self = .internalSet
      case "public(set)": self = .publicSet
      case "internal": self = .internal
      case "static": self = .static
      default: self = []
      }
    }
  }

  public struct PropertyData: Hashable {
    /// The name of the property
    public let name: String
    /// The Type annotation of the property if it's present
    public let typeAnnotation: String?
    /// Any comments associated with the property
    public let comment: String
    /// Modifier set for this type
    public let modifiers: Modifier
  }

  /// The name of the type.
  public let name: String
  /// The properties on this type
  public let properties: [PropertyData]
}

extension TypeProperties {
  struct MergeError: Error, CustomStringConvertible {

    init(errorMessage: String) {
      self.errorMessage = errorMessage
    }

    var description: String { errorMessage }

    private let errorMessage: String
  }
}

extension TypeProperties.MergeError {
  static var invalidNames = TypeProperties.MergeError(
    errorMessage: "Invalid types - the type names must match to be merged.")
}

extension TypeProperties {
  func merge(with other: TypeProperties?) throws -> TypeProperties {
    guard let other = other else {
      return self
    }
    guard name == other.name else {
      throw MergeError.invalidNames
    }
    return TypeProperties(
      name: name,
      properties: Array(Set(properties).union(Set(other.properties))))
  }
}
