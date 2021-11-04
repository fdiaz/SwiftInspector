// Created by Dan Federman on 2/2/21.
//
// Copyright © 2021 Dan Federman
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

/// An enum that describes a parsed type in a canonical form.
public enum TypeDescription: Codable, Hashable {
  /// A root type with possible generics. e.g. Int, or Array<Int>
  indirect case simple(name: String, generics: [TypeDescription])
  /// A nested type with possible generics. e.g. Array.Element or Swift.Array<Element>
  indirect case nested(name: String, parentType: TypeDescription, generics: [TypeDescription])
  /// A composed type. e.g. Identifiable & Equatable
  indirect case composition([TypeDescription])
  /// An optional type. e.g. Int?
  indirect case optional(TypeDescription)
  /// An implicitly unwrapped optional type. e.g. Int!
  indirect case implicitlyUnwrappedOptional(TypeDescription)
  /// An opaque type that conforms to a protocol. e.g. some Equatable
  indirect case some(TypeDescription)
  /// A meta type. e.g. `Int.Type` or `Equatable.Protocol`
  indirect case metatype(TypeDescription, isType: Bool)
  /// A type identifier with a specifier or attributes. e.g. `inout Int` or `@autoclosure () -> Void`
  indirect case attributed(TypeDescription, specifier: String?, attributes: [String]?)
  /// An array. e.g. [Int]
  indirect case array(element: TypeDescription)
  /// A dictionary. e.g. [Int: String]
  indirect case dictionary(key: TypeDescription, value: TypeDescription)
  /// A tuple. e.g. (Int, String)
  indirect case tuple([TypeDescription])
  /// A closure. e.g. (Int, Double) throws -> String
  indirect case closure(arguments: [TypeDescription], doesThrow: Bool, returnType: TypeDescription)
  /// A type that can't be represented by the above cases.
  case unknown(text: String)

  /// Creates a type description of case `.nested` with the given name as the name and the receiver as the parent type.
  /// If no parent is provided, creates a type description of case `.simple`.
  ///
  /// - Parameters:
  ///   - name: The simple name of the returned type.
  ///   - parent: The parent type for the returned type.
  /// - Note: This method only makes sense when the `parent` is of case  `simple`, `nested`, `optional`, and `implicitlyUnwrappedOptional`.
  init(name: String, parent: TypeDescription?) {
    if let parent = parent {
      self = .nested(name: name, parentType: parent)
    } else {
      self = .simple(name: name)
    }
  }

  /// A shortcut for creating a `simple` case without any generic types.
  public static func simple(name: String) -> TypeDescription {
    .simple(name: name, generics: [])
  }

  /// A shortcut for creating a `nested` case without any generic types.
  public static func nested(name: String, parentType: TypeDescription) -> TypeDescription {
    .nested(name: name, parentType: parentType, generics: [])
  }

  /// A canonical representation of this type that can be used as source code.
  public var asSource: String {
    switch self {
    case let .simple(name, generics):
      if generics.isEmpty {
        return name
      } else {
        return "\(name)<\(generics.map { $0.asSource }.joined(separator: ", "))>"
      }
    case let .composition(types):
      return types.map { $0.asSource }.joined(separator: " & ")
    case let .optional(type):
      return "\(type.asSource)?"
    case let .implicitlyUnwrappedOptional(type):
      return "\(type.asSource)!"
    case let .nested(name, parentType, generics):
      if generics.isEmpty {
        return "\(parentType.asSource).\(name)"
      } else {
        return "\(parentType.asSource).\(name)<\(generics.map { $0.asSource }.joined(separator: ", "))>"
      }
    case let .metatype(type, isType):
      return "\(type.asSource).\(isType ? "Type" : "Protocol")"
    case let .some(type):
      return "some \(type.asSource)"
    case let .attributed(type, specifier, attributes):
      func attributesFromList(_ attributes: [String]) -> String {
        attributes
          .map { "@\($0)" }
          .joined(separator: " ")
      }
      switch (specifier, attributes) {
      case let (.some(specifier), .none):
        return "\(specifier) \(type.asSource)"
      case let (.none, .some(attributes)):
        return "\(attributesFromList(attributes)) \(type.asSource)"
      case let (.some(specifier), .some(attributes)):
        // This case likely represents an error.
        return "\(specifier) \(attributesFromList(attributes)) \(type.asSource)"
      case (.none, .none):
        // This case likely represents an error.
        return type.asSource
      }
    case let .array(element):
      return "Array<\(element.asSource)>"
    case let .dictionary(key, value):
      return "Dictionary<\(key.asSource), \(value.asSource)>"
    case let .tuple(types):
      return "(\(types.map { $0.asSource }.joined(separator: ", ")))"
    case let .closure(arguments, doesThrow, returnType):
      return "(\(arguments.map { $0.asSource }.joined(separator: ", ")))\(doesThrow ? " throws" : "") -> \(returnType.asSource)"
    case let .unknown(text):
      return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }
  }

  public init(from decoder: Decoder) throws {
    let values = try decoder.container(keyedBy: CodingKeys.self)
    let caseDescription = try values.decode(String.self, forKey: .caseDescription)
    switch caseDescription {
    case Self.simpleDescription:
      let text = try values.decode(String.self, forKey: .text)
      let typeDescriptions = try values.decode([Self].self, forKey: .typeDescriptions)
      self = .simple(name: text, generics: typeDescriptions)

    case Self.unknownDescription:
      let text = try values.decode(String.self, forKey: .text)
      self = .unknown(text: text)

    case Self.nestedDescription:
      let text = try values.decode(String.self, forKey: .text)
      let parentType = try values.decode(Self.self, forKey: .typeDescription)
      let typeDescriptions = try values.decode([Self].self, forKey: .typeDescriptions)
      self = .nested(name: text, parentType: parentType, generics: typeDescriptions)

    case Self.optionalDescription:
      let typeDescription = try values.decode(Self.self, forKey: .typeDescription)
      self = .optional(typeDescription)

    case Self.implicitlyUnwrappedOptionalDescription:
      let typeDescription = try values.decode(Self.self, forKey: .typeDescription)
      self = .implicitlyUnwrappedOptional(typeDescription)

    case Self.compositionDescription:
      let typeDescriptions = try values.decode([Self].self, forKey: .typeDescriptions)
      self = .composition(typeDescriptions)

    case Self.someDescription:
      let typeDescription = try values.decode(Self.self, forKey: .typeDescription)
      self = .some(typeDescription)

    case Self.metatypeDescription:
      let typeDescription = try values.decode(Self.self, forKey: .typeDescription)
      let isType = try values.decode(Bool.self, forKey: .isType)
      self = .metatype(typeDescription, isType: isType)

    case Self.attributedDescription:
      let typeDescription = try values.decode(Self.self, forKey: .typeDescription)
      let specifier = try values.decodeIfPresent(String.self, forKey: .specifier)
      let attributes = try values.decodeIfPresent([String].self, forKey: .attributes)
      self = .attributed(typeDescription, specifier: specifier, attributes: attributes)

    case Self.arrayDescription:
      let typeDescription = try values.decode(Self.self, forKey: .typeDescription)
      self = .array(element: typeDescription)

    case Self.dictionaryDescription:
      let key = try values.decode(Self.self, forKey: .dictionaryKey)
      let value = try values.decode(Self.self, forKey: .dictionaryValue)
      self = .dictionary(key: key, value: value)

    case Self.tupleDescription:
      let typeDescriptions = try values.decode([Self].self, forKey: .typeDescriptions)
      self = .tuple(typeDescriptions)

    case Self.closureDescription:
      let typeDescriptions = try values.decode([Self].self, forKey: .closureArguments)
      let doesThrow = try values.decode(Bool.self, forKey: .closureThrows)
      let typeDescription = try values.decode(Self.self, forKey: .closureReturn)
      self = .closure(arguments: typeDescriptions, doesThrow: doesThrow, returnType: typeDescription)

    default:
      throw CodingError.unknownCase
    }
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(caseDescription, forKey: .caseDescription)
    switch self {
    case let .simple(name, generics):
      try container.encode(name, forKey: .text)
      try container.encode(generics, forKey: .typeDescriptions)
    case let .unknown(text):
      try container.encode(text, forKey: .text)
    case let .optional(type),
         let .implicitlyUnwrappedOptional(type),
         let .array(type),
         let .some(type):
      try container.encode(type, forKey: .typeDescription)
    case let .tuple(types),
         let .composition(types):
      try container.encode(types, forKey: .typeDescriptions)
    case let .metatype(type, isType):
      try container.encode(type, forKey: .typeDescription)
      try container.encode(isType, forKey: .isType)
    case let .attributed(type, specifier: specifier, attributes: attributes):
      try container.encode(type, forKey: .typeDescription)
      try container.encodeIfPresent(specifier, forKey: .specifier)
      try container.encodeIfPresent(attributes, forKey: .attributes)
    case let .nested(name, parentType, generics):
      try container.encode(name, forKey: .text)
      try container.encode(parentType, forKey: .typeDescription)
      try container.encode(generics, forKey: .typeDescriptions)
    case let .dictionary(key, value):
      try container.encode(key, forKey: .dictionaryKey)
      try container.encode(value, forKey: .dictionaryValue)
    case let .closure(arguments, doesThrow, returnType):
      try container.encode(arguments, forKey: .closureArguments)
      try container.encode(doesThrow, forKey: .closureThrows)
      try container.encode(returnType, forKey: .closureReturn)
    }
  }

  enum CodingKeys: String, CodingKey {
    /// The value for this key is the case encoded as a String.
    case caseDescription
    /// The value for this key is an associated value of type String
    case text
    /// The value for this key is the associated value of type TypeDescription
    case typeDescription
    /// The value for this key is the associated value of type [TypeDescription]
    case typeDescriptions
    /// The value for this key represents whether a metatype is a Type (as opposed to a Protocol) and is of type Bool
    case isType
    /// The value for this key is the specifier on an attributed type of type String
    case specifier
    /// The value for this key is the attributes on an attributed type of type [String]
    case attributes
    /// The value for this key is a dictionary's key of type TypeDescription
    case dictionaryKey
    /// The value for this key is a dictionary's value of type TypeDescription
    case dictionaryValue
    /// The value for this key represents the list of types in a closure argument list and is of type [TypeDescription]
    case closureArguments
    /// The value for this key represents whether a closure `throws` and is of type Bool
    case closureThrows
    /// The value for this key represents the return type of a closure argument list and is of type TypeDescription
    case closureReturn
  }

  public enum CodingError: Error {
    case unknownCase
  }

  private var caseDescription: String {
    switch self {
    case .composition:
      return Self.compositionDescription
    case .implicitlyUnwrappedOptional:
      return Self.implicitlyUnwrappedOptionalDescription
    case .nested:
      return Self.nestedDescription
    case .optional:
      return Self.optionalDescription
    case .simple:
      return Self.simpleDescription
    case .some:
      return Self.someDescription
    case .metatype:
      return Self.metatypeDescription
    case .attributed:
      return Self.attributedDescription
    case .array:
      return Self.arrayDescription
    case .dictionary:
      return Self.dictionaryDescription
    case .tuple:
      return Self.tupleDescription
    case .closure:
      return Self.closureDescription
    case .unknown:
      return Self.unknownDescription
    }
  }

  private static let simpleDescription = "simple"
  private static let nestedDescription = "nested"
  private static let compositionDescription = "composition"
  private static let optionalDescription = "optional"
  private static let implicitlyUnwrappedOptionalDescription = "implicitlyUnwrappedOptional"
  private static let someDescription = "some"
  private static let metatypeDescription = "metatype"
  private static let attributedDescription = "attributed"
  private static let arrayDescription = "array"
  private static let dictionaryDescription = "dictionary"
  private static let tupleDescription = "tuple"
  private static let closureDescription = "closure"
  private static let unknownDescription = "unknown"
}

extension TypeSyntax {

  /// Returns the type description for the receiver.
  var typeDescription: TypeDescription {
    if let typeIdentifier = self.as(SimpleTypeIdentifierSyntax.self) {
      let genericTypeVisitor = GenericArgumentVisitor()
      if let genericArgumentClause = typeIdentifier.genericArgumentClause {
        genericTypeVisitor.walk(genericArgumentClause)
      }
      return .simple(
        name: typeIdentifier.name.text,
        generics: genericTypeVisitor.genericArguments)

    } else if let typeIdentifier = self.as(MemberTypeIdentifierSyntax.self) {
      let genericTypeVisitor = GenericArgumentVisitor()
      if let genericArgumentClause = typeIdentifier.genericArgumentClause {
        genericTypeVisitor.walk(genericArgumentClause)
      }
      return .nested(
        name: typeIdentifier.name.text,
        parentType: typeIdentifier.baseType.typeDescription,
        generics: genericTypeVisitor.genericArguments)

    } else if let typeIdentifiers = self.as(CompositionTypeSyntax.self) {
      return .composition(typeIdentifiers.elements.map { $0.type.typeDescription })

    } else if let typeIdentifier = self.as(OptionalTypeSyntax.self) {
      return .optional(typeIdentifier.wrappedType.typeDescription)

    } else if let typeIdentifier = self.as(ImplicitlyUnwrappedOptionalTypeSyntax.self) {
      return .implicitlyUnwrappedOptional(typeIdentifier.wrappedType.typeDescription)

    } else if let typeIdentifier = self.as(SomeTypeSyntax.self) {
      return .some(typeIdentifier.baseType.typeDescription)

    } else if let typeIdentifier = self.as(MetatypeTypeSyntax.self) {
      return .metatype(
        typeIdentifier.baseType.typeDescription,
        isType: typeIdentifier.typeOrProtocol.text == "Type")

    } else if let typeIdentifier = self.as(AttributedTypeSyntax.self) {
      return .attributed(
        typeIdentifier.baseType.typeDescription,
        specifier: typeIdentifier.specifier?.text,
        attributes: typeIdentifier.attributes?.compactMap {
          $0.as(AttributeSyntax.self)?.attributeName.text
        })

    } else if let typeIdentifier = self.as(ArrayTypeSyntax.self) {
      return .array(element: typeIdentifier.elementType.typeDescription)

    } else if let typeIdentifier = self.as(DictionaryTypeSyntax.self) {
      return .dictionary(
        key: typeIdentifier.keyType.typeDescription,
        value: typeIdentifier.valueType.typeDescription)

    } else if let typeIdentifiers = self.as(TupleTypeSyntax.self) {
      return .tuple(typeIdentifiers.elements.map { $0.type.typeDescription })

    } else if self.as(ClassRestrictionTypeSyntax.self) != nil {
      // A class restriction is the same as requiring inheriting from AnyObject:
      // https://forums.swift.org/t/class-only-protocols-class-vs-anyobject/11507/4
      return .simple(name: "AnyObject")

    } else if let typeIdentifier = self.as(FunctionTypeSyntax.self) {
      return .closure(
        arguments: typeIdentifier.arguments.map { $0.type.typeDescription },
        doesThrow: typeIdentifier.throwsOrRethrowsKeyword != nil,
        returnType: typeIdentifier.returnType.typeDescription)

    } else {
      assertionFailureOrPostNotification("TypeSyntax of unknown type. Defaulting to `description`.")
      // The description is a source-accurate description of this node,
      // so it is a reasonable fallback.
      return .unknown(text: description)
    }
  }
}

private final class GenericArgumentVisitor: SyntaxVisitor {

  private(set) var genericArguments = [TypeDescription]()

  override func visit(_ node: GenericArgumentSyntax) -> SyntaxVisitorContinueKind {
    genericArguments.append(node.argumentType.typeDescription)
    return .skipChildren
  }
}
