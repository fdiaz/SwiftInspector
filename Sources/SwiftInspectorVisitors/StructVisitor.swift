// Created by Dan Federman on 1/27/21.
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

public final class StructVisitor: SyntaxVisitor {

  public init(parentType: TypeDescription? = nil) {
    self.parentType = parentType
  }

  /// All of the structs found by this visitor.
  public var structs: [StructInfo] {
    [structInfo].compactMap { $0 } + innerStructs
  }

  /// Inner classes found by this visitor.
  public private(set) var innerClasses = [ClassInfo]()
  /// Inner enums found by this visitor.
  public private(set) var innerEnums = [EnumInfo]()

  public override func visit(_ node: StructDeclSyntax) -> SyntaxVisitorContinueKind {

    guard !hasFinishedParsingStruct else {
      assertionFailure("Encountered more than one top-level struct. This is a usage error: a single StructVisitor instance should start walking only over a node of type `StructDeclSyntax`")
      return .skipChildren
    }

    if let structInfo = structInfo {
      // Base case. We've previously found a struct declaration, so this must be an inner struct.
      // This struct visitor shouldn't recurse down into the children.
      // Instead, we'll use a new struct visitor to get the information from this struct.
      let newParentType = TypeDescription.createTypeWithName(structInfo.name, parent: self.parentType)

      let innerStructVisitor = StructVisitor(parentType: newParentType)
      innerStructVisitor.walk(node)

      innerStructs += innerStructVisitor.structs
      innerClasses += innerStructVisitor.innerClasses
      innerEnums += innerStructVisitor.innerEnums

      // We've already gotten information from the children from our inner struct visitor.
      return .skipChildren

    } else {
      // Recursive case. This is the first struct declaration we've come across.
      // We need to get its information and then visit children to see if there is more information we need.
      let name = node.identifier.text
      let typeInheritanceVisitor = TypeInheritanceVisitor()
      typeInheritanceVisitor.walk(node)

      structInfo = StructInfo(
        name: name,
        inheritsFromTypes: typeInheritanceVisitor.inheritsFromTypes,
        parentType: parentType)
      return .visitChildren
    }
  }

  public override func visitPost(_ node: StructDeclSyntax) {
    hasFinishedParsingStruct = node.identifier.text == structInfo?.name
  }

  public override func visit(_ node: ClassDeclSyntax) -> SyntaxVisitorContinueKind {
    if !hasFinishedParsingStruct, let structInfo = structInfo {
      // We've previously found a struct declaration, so this must be an inner class.
      let newParentType = TypeDescription.createTypeWithName(structInfo.name, parent: self.parentType)

      let classVisitor = ClassVisitor(parentType: newParentType)
      classVisitor.walk(node)
      innerClasses += classVisitor.classes
      innerStructs += classVisitor.innerStructs
      innerEnums += classVisitor.innerEnums

    } else {
      // We've encountered a class declaration before encountering a struct declaration. Something is wrong.
      assertionFailure("Encountered a top-level class. This is a usage error: a single StructVisitor instance should start walking only over a node of type `StructDeclSyntax`")
    }
    return .skipChildren
  }

  public override func visit(_ node: EnumDeclSyntax) -> SyntaxVisitorContinueKind {
    if !hasFinishedParsingStruct, let structInfo = structInfo {
      // We've previously found a struct declaration, so this must be an inner enum.
      let newParentType = TypeDescription.createTypeWithName(structInfo.name, parent: self.parentType)

      let enumVisitor = EnumVisitor(parentType: newParentType)
      enumVisitor.walk(node)
      innerEnums += enumVisitor.enums
      innerClasses += enumVisitor.innerClasses
      innerStructs += enumVisitor.innerStructs

    } else {
      // We've encountered an enum declaration before encountering a struct declaration. Something is wrong.
      assertionFailure("Encountered a top-level enum. This is a usage error: a single StructVisitor instance should start walking only over a node of type `StructDeclSyntax`")
    }
    return .skipChildren
  }

  public override func visit(_ node: ProtocolDeclSyntax) -> SyntaxVisitorContinueKind {
    // We've encountered a protocol declaration, which can only be defined at the top-level. Something is wrong.
    assertionFailure("Encountered a protocol. This is a usage error: a single StructVisitor instance should start walking only over a node of type `StructDeclSyntax`")
    return .skipChildren
  }

  public override func visit(_ node: ExtensionDeclSyntax) -> SyntaxVisitorContinueKind {
     // We've encountered an extension declaration, which can only be defined at the top-level. Something is wrong.
     assertionFailure("Encountered an extension. This is a usage error: a single ClassVisitor instance should start walking only over a node of type `ClassDeclSyntax`")
     return .skipChildren
   }

  // MARK: Private

  private let parentType: TypeDescription?
  private var hasFinishedParsingStruct = false
  private var structInfo: StructInfo?
  private var innerStructs = [StructInfo]()
}

public struct StructInfo: Codable, Equatable {
  public let name: String
  public let inheritsFromTypes: [TypeDescription]
  public let parentType: TypeDescription?
  // TODO: also find and expose properties on a struct
}
