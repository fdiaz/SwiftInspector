//  Created by Michael Bachand on 4/8/21.
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

import SwiftSyntax

// MARK: - TypeSyntaxVisitor

public final class TypeSyntaxVisitor: SyntaxVisitor {

  // MARK: Lifecycle

  public init(typeName: String) {
    self.typeName = typeName
  }

  // MARK: Public

  /// Information about each of the properties found on the type. `nil` if the type is not found.
  public private(set) var propertiesData: Set<PropertyData>?

  public override func visit(_ node: ClassDeclSyntax) -> SyntaxVisitorContinueKind {
    if node.identifier.text == typeName {
      processNode(node, members: node.members.members)
    }
    return .visitChildren
  }

  public override func visit(_ node: EnumDeclSyntax) -> SyntaxVisitorContinueKind {
    if node.identifier.text == typeName {
      processNode(node, members: node.members.members)
    }
    return .visitChildren
  }

  public override func visit(_ node: ProtocolDeclSyntax) -> SyntaxVisitorContinueKind {
    if node.identifier.text == typeName {
      processNode(node, members: node.members.members)
    }
    return .visitChildren
  }

  public override func visit(_ node: StructDeclSyntax) -> SyntaxVisitorContinueKind {
    if node.identifier.text == typeName {
      processNode(node, members: node.members.members)
    }
    return .visitChildren
  }

  public override func visit(_ node: ExtensionDeclSyntax) -> SyntaxVisitorContinueKind {
    if
      let typeIdentifier = node.extendedType.as(SimpleTypeIdentifierSyntax.self),
      typeIdentifier.name.text == typeName
    {
      processNode(node, members: node.members.members)
    }
    return .visitChildren
  }

  // MARK: Internal

  /// Merges the new property data with property data we've already found.
  static func merge(
    _ newPropertiesData: Set<PropertyData>,
    into existingPropertiesData: Set<PropertyData>?)
  -> Set<PropertyData>
  {
    if let existingPropertiesData = existingPropertiesData {
      return newPropertiesData.union(existingPropertiesData)
    }
    else {
      return newPropertiesData
    }
  }

  // MARK: Private

  private let typeName: String

  private func processNode<Node>(_ node: Node, members: MemberDeclListSyntax) where Node: SyntaxProtocol {
    let propertyVisitor = PropertySyntaxVisitor(typeName: typeName)
    propertyVisitor.walk(node)
    propertiesData = Self.merge(propertyVisitor.propertiesData, into: propertiesData)
  }
}

// MARK: - PropertySyntaxVisitor

private final class PropertySyntaxVisitor: SyntaxVisitor {

  init(typeName: String) {
    self.typeName = typeName
  }

  /// Information about each of the properties found on the type.
  private(set) var propertiesData: Set<PropertyData> = []

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
          propertiesData.insert(.init(
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
        propertiesData.insert(.init(
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

  private func findModifiers(from node: VariableDeclSyntax) -> PropertyData.Modifier {
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

    var modifier = modifiersString.reduce(PropertyData.Modifier()) { result, stringValue in
      let modifier = PropertyData.Modifier(stringValue: stringValue)
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

// MARK: - PropertyData

public struct PropertyData: Hashable {
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

  /// The name of the property
  public let name: String
  /// The Type annotation of the property if it's present
  public let typeAnnotation: String?
  /// Any comments associated with the property
  public let comment: String
  /// Modifier set for this type
  public let modifiers: Modifier
}
