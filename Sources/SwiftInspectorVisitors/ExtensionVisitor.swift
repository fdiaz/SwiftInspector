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
  /// Inner typealiases declarations found by this visitor.
  public private(set) var innerTypealiases = [TypealiasInfo]()

  public override func visit(_ node: ExtensionDeclSyntax) -> SyntaxVisitorContinueKind {

    guard !hasFinishedParsingExtension else {
      assertionFailureOrPostNotification("Encountered more than one top-level extension. This is a usage error: a single ExtensionVisitor instance should start walking only over a node of type `ExtensionDeclSyntax`")
      return .skipChildren
    }

    let typeInheritanceVisitor = TypeInheritanceVisitor()
    if let inheritanceClause = node.inheritanceClause {
      typeInheritanceVisitor.walk(inheritanceClause)
    }

    let genericRequirementVisitor = GenericRequirementVisitor()
    if let genericWhereClause = node.genericWhereClause {
      genericRequirementVisitor.walk(genericWhereClause)
    }

    let declarationModifierVisitor = DeclarationModifierVisitor()
    if let modifiers = node.modifiers {
      declarationModifierVisitor.walk(modifiers)
    }

    extensionInfo = ExtensionInfo(
      typeDescription: node.extendedType.typeDescription,
      inheritsFromTypes: typeInheritanceVisitor.inheritsFromTypes,
      genericRequirements: genericRequirementVisitor.genericRequirements,
      modifiers: declarationModifierVisitor.modifiers,
      properties: [],
      functionDeclarations: [])
    return .visitChildren
  }

  public override func visitPost(_ node: ExtensionDeclSyntax) {
    hasFinishedParsingExtension = true
  }

  public override func visit(_ node: ClassDeclSyntax) -> SyntaxVisitorContinueKind {
    visitNestableDeclaration(node: node)
  }

  public override func visit(_ node: StructDeclSyntax) -> SyntaxVisitorContinueKind {
    visitNestableDeclaration(node: node)
  }

  public override func visit(_ node: EnumDeclSyntax) -> SyntaxVisitorContinueKind {
    visitNestableDeclaration(node: node)
  }

  public override func visit(_ node: ProtocolDeclSyntax) -> SyntaxVisitorContinueKind {
    // We've encountered a protocol declaration, which can only be defined at the top-level. Something is wrong.
    assertionFailureOrPostNotification("Encountered a protocol. This is a usage error: a single ExtensionVisitor instance should start walking only over a node of type `ExtensionDeclSyntax`")
    return .skipChildren
  }

  public override func visit(_ node: TypealiasDeclSyntax) -> SyntaxVisitorContinueKind {
    let typealiasVisitor = TypealiasVisitor(parentType: extensionInfo?.typeDescription)
    typealiasVisitor.walk(node)

    innerTypealiases.append(contentsOf: typealiasVisitor.typealiases)

    // We don't need to visit children because our visitor just did that for us.
    return .skipChildren
  }

  public override func visit(_ node: VariableDeclSyntax) -> SyntaxVisitorContinueKind {
    let propertyVisitor = PropertyVisitor()
    propertyVisitor.walk(node)

    extensionInfo?.properties.append(contentsOf: propertyVisitor.properties)

    // We don't need to visit children because our visitor just did that for us.
    return .skipChildren
  }

  public override func visit(_ node: FunctionDeclSyntax) -> SyntaxVisitorContinueKind {
    let functionDeclarationVisitor = FunctionDeclarationVisitor()
    functionDeclarationVisitor.walk(node)

    extensionInfo?.functionDeclarations.append(contentsOf: functionDeclarationVisitor.functionDeclarations)

    // We don't need to visit children because our visitor just did that for us.
    return .skipChildren
  }

  // MARK: Private

  private func visitNestableDeclaration<DeclSyntax: NestableDeclSyntax>(node: DeclSyntax) -> SyntaxVisitorContinueKind {
    if !hasFinishedParsingExtension, let extensionInfo = extensionInfo {
      // We've previously found an extension declaration, so this must be an inner declaration.
      let declarationVisitor = NestableTypeVisitor(parentType: extensionInfo.typeDescription)
      declarationVisitor.walk(node)

      innerClasses += declarationVisitor.classes
      innerStructs += declarationVisitor.structs
      innerEnums += declarationVisitor.enums
      innerTypealiases += declarationVisitor.typealiases

    } else {
      // We've encountered a class declaration before encountering an extension declaration. Something is wrong.
      assertionFailureOrPostNotification("Encountered a top-level declaration. This is a usage error: a single ExtensionVisitor instance should start walking only over a node of type `ExtensionDeclSyntax`")
    }
    return .skipChildren
  }

  private var hasFinishedParsingExtension = false
}

public struct ExtensionInfo: Codable, Hashable {
  public let typeDescription: TypeDescription
  public let inheritsFromTypes: [TypeDescription]
  public let genericRequirements: [GenericRequirement]
  public let modifiers: Modifiers
  public fileprivate(set) var properties: [PropertyInfo]
  public fileprivate(set) var functionDeclarations: [FunctionDeclarationInfo]
}
