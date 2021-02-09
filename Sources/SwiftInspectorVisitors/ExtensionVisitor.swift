// Created by Dan Federman on 1/28/21.
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

public final class ExtensionVisitor: SyntaxVisitor {

  /// The extension found by this visitor.
  public private(set) var extensionInfo: ExtensionInfo?
  /// Inner structs found by this visitor.
  public private(set) var innerStructs = [StructInfo]()
  /// Inner classes found by this visitor.
  public private(set) var innerClasses = [ClassInfo]()
  /// Inner enums found by this visitor.
  public private(set) var innerEnums = [EnumInfo]()

  public override func visit(_ node: ExtensionDeclSyntax) -> SyntaxVisitorContinueKind {

    guard !hasFinishedParsingExtension else {
      assertionFailure("Encountered more than one top-level extension. This is a usage error: a single ExtensionVisitor instance should start walking only over a node of type `ExtensionDeclSyntax`")
      return .skipChildren
    }

    let typeInheritanceVisitor = TypeInheritanceVisitor()
    typeInheritanceVisitor.walk(node)
    let genericRequirementsVisitor = GenericRequirementVisitor()
    genericRequirementsVisitor.walk(node)

    let declarationModifierVisitor = DeclarationModifierVisitor()
    if let modifiers = node.modifiers {
      declarationModifierVisitor.walk(modifiers)
    }

    extensionInfo = ExtensionInfo(
      typeDescription: node.extendedType.typeDescription,
      inheritsFromTypes: typeInheritanceVisitor.inheritsFromTypes,
      genericRequirements: genericRequirementsVisitor.genericRequirements,
      modifiers: .init(declarationModifierVisitor.modifiers))
    return .visitChildren
  }

  public override func visitPost(_ node: ExtensionDeclSyntax) {
    hasFinishedParsingExtension = true
  }

  public override func visit(_ node: ClassDeclSyntax) -> SyntaxVisitorContinueKind {
    if !hasFinishedParsingExtension, let extensionInfo = extensionInfo {
      // We've previously found an extension declaration, so this must be an inner class.
      let classVisitor = ClassVisitor(parentType: extensionInfo.typeDescription)
      classVisitor.walk(node)

      innerClasses += classVisitor.classes
      innerStructs += classVisitor.innerStructs
      innerEnums += classVisitor.innerEnums

    } else {
      // We've encountered a class declaration before encountering an extension declaration. Something is wrong.
      assertionFailure("Encountered a top-level class. This is a usage error: a single ExtensionVisitor instance should start walking only over a node of type `ExtensionDeclSyntax`")
    }
    return .skipChildren
  }

  public override func visit(_ node: StructDeclSyntax) -> SyntaxVisitorContinueKind {
    if !hasFinishedParsingExtension, let extensionInfo = extensionInfo {
      // We've previously found an extension declaration, so this must be an inner struct.
      let structVisitor = StructVisitor(parentType: extensionInfo.typeDescription)
      structVisitor.walk(node)

      innerStructs += structVisitor.structs
      innerClasses += structVisitor.innerClasses
      innerEnums += structVisitor.innerEnums

    } else {
      // We've encountered a class declaration before encountering an extension declaration. Something is wrong.
      assertionFailure("Encountered a top-level struct. This is a usage error: a single ExtensionVisitor instance should start walking only over a node of type `ExtensionDeclSyntax`")
    }

    return .skipChildren
  }

  public override func visit(_ node: EnumDeclSyntax) -> SyntaxVisitorContinueKind {
    if !hasFinishedParsingExtension, let extensionInfo = extensionInfo {
      // We've previously found a extension declaration, so this must be an inner enum.
      let enumVisitor = EnumVisitor(parentType: extensionInfo.typeDescription)
      enumVisitor.walk(node)

      innerEnums += enumVisitor.enums
      innerStructs += enumVisitor.innerStructs
      innerClasses += enumVisitor.innerClasses

    } else {
      // We've encountered a enum declaration before encountering an extension declaration. Something is wrong.
      assertionFailure("Encountered a top-level enum. This is a usage error: a single ExtensionVisitor instance should start walking only over a node of type `ExtensionDeclSyntax`")
    }
    return .skipChildren
  }

  public override func visit(_ node: ProtocolDeclSyntax) -> SyntaxVisitorContinueKind {
    // We've encountered a protocol declaration, which can only be defined at the top-level. Something is wrong.
    assertionFailure("Encountered a protocol. This is a usage error: a single ExtensionVisitor instance should start walking only over a node of type `ExtensionDeclSyntax`")
    return .skipChildren
  }

  // MARK: Private

  private var hasFinishedParsingExtension = false
}

public struct ExtensionInfo: Codable, Equatable {
  public let typeDescription: TypeDescription
  public private(set) var inheritsFromTypes: [TypeDescription]
  public private(set) var genericRequirements: [GenericRequirement]
  public let modifiers: Set<String>
  // TODO: also find and expose computed properties
}
