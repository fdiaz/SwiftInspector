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

public enum TypeDescription: Codable, Equatable, CustomStringConvertible {
  case simple(name: String)
  indirect case member(name: String, baseType: TypeDescription)
  indirect case composition([TypeDescription])
  indirect case optional(TypeDescription)
  indirect case implicitlyUnwrappedOptional(TypeDescription)
  indirect case array(TypeDescription)
  indirect case dictionary(key: TypeDescription, value: TypeDescription)
  indirect case tuple([TypeDescription])
  case unknown(text: String)

  /*
   * Note that we do not yet support the following syntax types:
   * SomeTypeSyntax
   * MetatypeTypeSyntax
   * FunctionTypeSyntax
   * AttributedTypeSyntax
   * UnknownTypeSyntax
   *
   * We will likely need to add these types at some point in the future.
   * We’ll Get There™
   */

  /// A description of this type that can be used for code-generation to represent this type.
  public var description: String {
    switch self {
    case let .simple(name):
      return name
    case let .array(type):
      return "[\(type)]"
    case let .composition(types):
      return types.map { $0.description }.joined(separator: " & ")
    case let .optional(type):
      return "\(type)?"
    case let .implicitlyUnwrappedOptional(type):
      return "\(type)!"
    case let .dictionary(key, value):
      return "[\(key): \(value)]"
    case let .member(name, baseType):
      return "\(baseType).\(name)"
    case let .tuple(types):
      return "(\(types.map { $0.description }.joined(separator: ", ")))"
    case let .unknown(text):
      return text
    }
  }

  public init(from decoder: Decoder) throws {
    let values = try decoder.container(keyedBy: CodingKeys.self)
    let caseDescription = try values.decode(String.self, forKey: .caseDescription)
    if caseDescription == Self.simpleDescription {
      let text = try values.decode(String.self, forKey: .text)
      self = .simple(name: text)

    } else if caseDescription == Self.unknownDescription {
      let text = try values.decode(String.self, forKey: .text)
      self = .unknown(text: text)

    } else if caseDescription == Self.memberDescription {
      let text = try values.decode(String.self, forKey: .text)
      let baseType = try values.decode(Self.self, forKey: .typeDescription)
      self = .member(name: text, baseType: baseType)

    } else if caseDescription == Self.optionalDescription {
      let typeDescription = try values.decode(Self.self, forKey: .typeDescription)
      self = .optional(typeDescription)

    } else if caseDescription == Self.implicitlyUnwrappedOptionalDescription {
      let typeDescription = try values.decode(Self.self, forKey: .typeDescription)
      self = .implicitlyUnwrappedOptional(typeDescription)

    } else if caseDescription == Self.arrayDescription {
      let typeDescription = try values.decode(Self.self, forKey: .typeDescription)
      self = .array(typeDescription)

    } else if caseDescription == Self.dictionaryDescription {
      let key = try values.decode(Self.self, forKey: .typeDescriptionKey)
      let value = try values.decode(Self.self, forKey: .typeDescriptionValue)
      self = .dictionary(key: key, value: value)

    } else if caseDescription == Self.compositionDescription {
      let typeDescriptions = try values.decode([Self].self, forKey: .typeDescriptions)
      self = .composition(typeDescriptions)

    } else if caseDescription == Self.tupleDescription {
      let typeDescriptions = try values.decode([Self].self, forKey: .typeDescriptions)
      self = .tuple(typeDescriptions)

    } else {
      throw CodingError.unknownCase
    }
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(caseDescription, forKey: .caseDescription)
    switch self {
    case let .simple(name):
      try container.encode(name, forKey: .text)
    case let .unknown(text):
      try container.encode(text, forKey: .text)
    case let .optional(type),
         let .array(type),
         let .implicitlyUnwrappedOptional(type):
      try container.encode(type, forKey: .typeDescription)
    case let .tuple(types),
         let .composition(types):
      try container.encode(types, forKey: .typeDescriptions)
    case let .dictionary(key, value):
      try container.encode(key, forKey: .typeDescriptionKey)
      try container.encode(value, forKey: .typeDescriptionValue)
    case let .member(name, baseType):
      try container.encode(name, forKey: .text)
      try container.encode(baseType, forKey: .typeDescription)
    }
  }

  enum CodingKeys: String, CodingKey {
    case caseDescription
    case text
    case typeDescription
    case typeDescriptions
    case typeDescriptionKey
    case typeDescriptionValue
  }

  enum CodingError: Error {
    case unknownCase
  }

  /// - Parameters:
  ///   - name: The simple name of the returned type.
  ///   - parent: The parent type for the returned type.
  /// - Returns: Returns a type description of case `.member` with the given name as the name and the receiver as the base type.
  /// - Note: This method only makes sense when the `parent` is of case  `simple`, `member`, `optional`, and `implicitlyUnwrappedOptional`.
  static func createTypeWithName(_ name: String, parent: TypeDescription?) -> TypeDescription {
    if let parent = parent {
      return .member(name: name, baseType: parent)
    } else {
      return .simple(name: name)
    }
  }

  private var caseDescription: String {
    switch self {
    case .array:
      return Self.arrayDescription
    case .composition:
      return Self.compositionDescription
    case .dictionary:
      return Self.dictionaryDescription
    case .implicitlyUnwrappedOptional:
      return Self.implicitlyUnwrappedOptionalDescription
    case .member:
      return Self.memberDescription
    case .optional:
      return Self.optionalDescription
    case .simple:
      return Self.simpleDescription
    case .tuple:
      return Self.tupleDescription
    case .unknown:
      return Self.unknownDescription
    }
  }

  private static let simpleDescription = "simple"
  private static let memberDescription = "member"
  private static let compositionDescription = "composition"
  private static let optionalDescription = "optional"
  private static let implicitlyUnwrappedOptionalDescription = "implicitlyUnwrappedOptional"
  private static let arrayDescription = "array"
  private static let dictionaryDescription = "dictionary"
  private static let tupleDescription = "tuple"
  private static let unknownDescription = "unknown"
}

extension TypeSyntax {

  /// Returns the type description for the receiver.
  /// - Warning: Do not call on a type syntax node of type `ClassRestrictionTypeSyntax`,
  ///            `SomeTypeSyntax`, `MetatypeTypeSyntax`, `FunctionTypeSyntax`,
  ///            `AttributedTypeSyntax`, or `UnknownTypeSyntax`
  var typeDescription: TypeDescription {
    if let typeIdentifier = self.as(SimpleTypeIdentifierSyntax.self) {
      return .simple(name: typeIdentifier.name.text)

    } else if let typeIdentifier = self.as(MemberTypeIdentifierSyntax.self) {
      return .member(
        name: typeIdentifier.name.text,
        baseType: typeIdentifier.baseType.typeDescription)

    } else if let typeIdentifiers = self.as(CompositionTypeSyntax.self) {
      return .composition(typeIdentifiers.elements.map { $0.type.typeDescription })

    } else if let typeIdentifier = self.as(OptionalTypeSyntax.self) {
      return .optional(typeIdentifier.wrappedType.typeDescription)

    } else if let typeIdentifier = self.as(ImplicitlyUnwrappedOptionalTypeSyntax.self) {
      return .implicitlyUnwrappedOptional(typeIdentifier.wrappedType.typeDescription)

    } else if let typeIdentifier = self.as(ArrayTypeSyntax.self) {
      return .array(typeIdentifier.elementType.typeDescription)

    } else if let typeIdentifier = self.as(DictionaryTypeSyntax.self) {
      return .dictionary(
        key: typeIdentifier.keyType.typeDescription,
        value: typeIdentifier.valueType.typeDescription)

    } else if let typeIdentifiers = self.as(TupleTypeSyntax.self) {
      return .tuple(typeIdentifiers.elements.map { $0.type.typeDescription })

    } else if self.as(ClassRestrictionTypeSyntax.self) != nil {
      // A class restriction is the same as requiring inheriting from AnyObject.
      return .simple(name: "AnyObject")

    } else {
      assertionFailure("TypeSyntax of unexpected type. Defaulting to `description`.")
      // The description is a source-accurate description of this node,
      // so it is a reasonable fallback.
      return .unknown(text: description.trimmingCharacters(in: .whitespacesAndNewlines))
    }
  }
}
