// Created by francisco_diaz on 7/7/21.
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

// MARK: - PropertyVisitor

public final class PropertyVisitor: SyntaxVisitor {

  /// Information about each of the properties found on the type.
  private(set) var properties: [PropertyInfo] = []

  public override func visit(_ node: VariableDeclSyntax) -> SyntaxVisitorContinueKind {
    let modifier = findModifiers(from: node)

    var lastFoundType: TypeDescription?
    node.bindings.reversed().forEach { binding in
      if let identifier = binding.pattern.as(IdentifierPatternSyntax.self) {
        let typeName = findTypeDescription(from: binding.typeAnnotation)
        // If we find a type name on the n element, but n-1 doesn't have an explicit type name, n-1 has the same type as n
        // e.g. let red: Int, green, blue: Double
        // where both green and blue are of type Double
        if let typeName = typeName { lastFoundType = typeName }
        properties.append(.init(
                            name: identifier.identifier.text,
                            typeDescription: lastFoundType,
                            modifiers: modifier))
      }
    }

    return .skipChildren
  }

  public override func visit(_ node: ClassDeclSyntax) -> SyntaxVisitorContinueKind {
    .skipChildren
  }

  public override func visit(_ node: StructDeclSyntax) -> SyntaxVisitorContinueKind {
    .skipChildren
  }

  public override func visit(_ node: EnumDeclSyntax) -> SyntaxVisitorContinueKind {
    .skipChildren
  }

  public override func visit(_ node: ProtocolDeclSyntax) -> SyntaxVisitorContinueKind {
    .skipChildren
  }

  public override func visit(_ node: ExtensionDeclSyntax) -> SyntaxVisitorContinueKind {
    .skipChildren
  }

  // MARK: Private

  private func findModifiers(from node: VariableDeclSyntax) -> PropertyInfo.Modifier {
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

    var modifier = modifiersString.reduce(PropertyInfo.Modifier()) { result, stringValue in
      let modifier = PropertyInfo.Modifier(stringValue: stringValue)
      return result.union(modifier)
    }

    // If there are no explicit modifiers, this is an internal property
    if !modifier.contains(.open) &&
        !modifier.contains(.public) &&
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

  private func findTypeDescription(from node: TypeAnnotationSyntax?) -> TypeDescription? {
    guard
      let typeAnnotation = node,
      let typeSyntax = typeAnnotation.type.as(TypeSyntax.self) else {
      // No type annotation was found.
      // e.g.:
      // public let thing: String = "Hello" has a type annotation, String which makes this easy
      // public let thing = "Hello" does not have a type annotation.
      return nil
    }
    return typeSyntax.typeDescription
  }
}

// MARK: - PropertyInfo

public struct PropertyInfo: Codable, Hashable, CustomDebugStringConvertible {
  /// The name of the property
  public let name: String
  /// The type of the property if it's present
  public let typeDescription: TypeDescription?
  /// Modifier set for this type
  public let modifiers: Modifier
  /// The paradigm of this property, along with any associated data that cannot be reasonably represented statically.
  public let paradigm: Paradigm

  public var debugDescription: String {
    "\(modifiers.rawValue) \(name) \(typeDescription?.asSource ?? "")"
  }
}

// MARK: - PropertyInfo.Modifier

extension PropertyInfo {
  public struct Modifier: Codable, Hashable, OptionSet {
    public let rawValue: Int

    // general accessors
    public static let `open` = Modifier(rawValue: 1 << 0)
    public static let `internal` = Modifier(rawValue: 1 << 1)
    public static let `public` = Modifier(rawValue: 1 << 2)
    public static let `private` = Modifier(rawValue: 1 << 3)
    public static let `fileprivate` = Modifier(rawValue: 1 << 4)
    // set accessors
    public static let privateSet = Modifier(rawValue: 1 << 5)
    public static let internalSet = Modifier(rawValue: 1 << 6)
    public static let publicSet = Modifier(rawValue: 1 << 7)
    // access control
    public static let `instance` = Modifier(rawValue: 1 << 8)
    public static let `static` = Modifier(rawValue: 1 << 9)

    public init(rawValue: Int)  {
      self.rawValue = rawValue
    }

    public init(stringValue: String) {
      switch stringValue {
      case "open": self = .open
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
}

// MARK: - PropertyInfo.Paradigm

extension PropertyInfo {
  public enum Paradigm {
    /// A `let` property with no `=`.
    case undefinedConstant
    /// A `let` property with an `=`.
    /// - Parameter initializerDescription: A source-accurate description of the initializer.
    case definedConstant(_ initializerDescription: String)
    /// A  `var` property with no `=`.
    case undefinedVariable
    /// A `var ` property with an `=`.
    /// - Parameter initializerDescription: A source-accurate description of the initializer.
    case definedVariable(_ initializerDescription: String)
    /// A computed `var` property.
    /// - Parameter codeBlockDesciption: A source-accurate description of the code block which computes the value.
    case computedVariable(_ codeBlockDesciption: String)
  }
}
