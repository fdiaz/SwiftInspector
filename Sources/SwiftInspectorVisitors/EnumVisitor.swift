// Created by Dan Federman on 1/29/21.
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

import Foundation
import SwiftSyntax

public final class EnumVisitor: SyntaxVisitor {

  public init(parentType: TypeDescription? = nil) {
    self.parentType = parentType
  }

  /// All of the classes found by this visitor.
  public var enums: [EnumInfo] {
    [enumInfo].compactMap { $0 } + innerEnums
  }

  /// Inner structs found by this visitor.
  public private(set) var innerStructs = [StructInfo]()
  /// Inner classes found by this visitor.
  public private(set) var innerClasses = [ClassInfo]()

  public override func visit(_ node: EnumDeclSyntax) -> SyntaxVisitorContinueKind {

    guard !hasFinishedParsingEnum else {
      assertionFailure("Encountered more than one top-level enum. This is a usage error: a single EnumVisitor instance should start walking only over a node of type `EnumDeclSyntax`")
      return .skipChildren
    }

    if let enumInfo = enumInfo {
      // Base case. We've previously found an enum declaration, so this must be an inner class.
      // This class visitor shouldn't recurse down into the children.
      // Instead, we'll use a new class visitor to get the information from this class.
      let newParentType = TypeDescription.typeDescriptionWithName(enumInfo.name, parent: self.parentType)
      let innerEnumVisitor = EnumVisitor(parentType: newParentType)
      innerEnumVisitor.walk(node)

      innerEnums += innerEnumVisitor.enums
      innerClasses += innerEnumVisitor.innerClasses
      innerStructs += innerEnumVisitor.innerStructs

      // We've already gotten information from the children from our inner struct visitor.
      return .skipChildren

    } else {
      // Recursive case. This is the first class declaration we've come across.
      // We need to get its information and then visit children to see if there is more information we need.
      let name = node.identifier.text
      let typeInheritanceVisitor = TypeInheritanceVisitor()
      typeInheritanceVisitor.walk(node)

      enumInfo = EnumInfo(
        name: name,
        inheritsFromTypes: typeInheritanceVisitor.inheritsFromTypes,
        parentType: parentType)
      return .visitChildren
    }
  }

  public override func visitPost(_ node: EnumDeclSyntax) {
    hasFinishedParsingEnum = node.identifier.text == enumInfo?.name
  }

  public override func visit(_ node: StructDeclSyntax) -> SyntaxVisitorContinueKind {
    if !hasFinishedParsingEnum, let enumInfo = enumInfo {
      // We've previously found an enum declaration, so this must be an inner struct.
      let newParentType = TypeDescription.typeDescriptionWithName(enumInfo.name, parent: self.parentType)

      let structVisitor = StructVisitor(parentType: newParentType)
      structVisitor.walk(node)
      innerStructs += structVisitor.structs
      innerEnums += structVisitor.innerEnums
      innerClasses += structVisitor.innerClasses

    } else {
      // We've encountered a struct declaration before encountering an enum declaration. Something is wrong.
      assertionFailure("Encountered a top-level struct. This is a usage error: a single EnumVisitor instance should start walking only over a node of type `EnumDeclSyntax`")
    }
    return .skipChildren
  }

  public override func visit(_ node: ClassDeclSyntax) -> SyntaxVisitorContinueKind {
    if !hasFinishedParsingEnum, let enumInfo = enumInfo {
      // We've previously found an enum declaration, so this must be an inner enum.
      let newParentType = TypeDescription.typeDescriptionWithName(enumInfo.name, parent: self.parentType)

      let classVisitor = ClassVisitor(parentType: newParentType)
      classVisitor.walk(node)
      innerClasses += classVisitor.classes
      innerStructs += classVisitor.innerStructs
      innerEnums += classVisitor.innerEnums

    } else {
      // We've encountered an class declaration before encountering an enum declaration. Something is wrong.
      assertionFailure("Encountered a top-level enum. This is a usage error: a single EnumVisitor instance should start walking only over a node of type `EnumDeclSyntax`")
    }
    return .skipChildren
  }

  public override func visit(_ node: ProtocolDeclSyntax) -> SyntaxVisitorContinueKind {
    // We've encountered a protocol declaration, which can only be defined at the top-level. Something is wrong.
    assertionFailure("Encountered a protocol. This is a usage error: a single EnumVisitor instance should start walking only over a node of type `EnumDeclSyntax`")
    return .skipChildren
  }

  public override func visit(_ node: ExtensionDeclSyntax) -> SyntaxVisitorContinueKind {
    // We've encountered an extension declaration, which can only be defined at the top-level. Something is wrong.
    assertionFailure("Encountered an extension. This is a usage error: a single EnumVisitor instance should start walking only over a node of type `EnumDeclSyntax`")
    return .skipChildren
  }

  // MARK: Private

  private let parentType: TypeDescription?
  private var hasFinishedParsingEnum = false
  private var enumInfo: EnumInfo?
  private var innerEnums = [EnumInfo]()
}

public struct EnumInfo: Codable, Equatable {
  public let name: String
  public let inheritsFromTypes: [TypeDescription]
  public let parentType: TypeDescription?
  // TODO: also find and expose properties on a class
}
