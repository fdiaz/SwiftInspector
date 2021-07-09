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

import SwiftSyntax

public final class ProtocolVisitor: SyntaxVisitor {

  public private(set) var protocolInfo: ProtocolInfo?

  public override func visit(_ node: ProtocolDeclSyntax) -> SyntaxVisitorContinueKind {

    guard !hasFinishedParsingProtocol else {
      assertionFailure("Encountered more than one top-level protocol. This is a usage error: a single ProtocolVisitor instance should start walking only over a node of type `ProtocolDeclSyntax`")
      return .skipChildren
    }
    let name = node.identifier.text

    let associatedtypeVisitor = AssociatedtypeVisitor()
    associatedtypeVisitor.walk(node.members)

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

    let typealiasVisitor = TypealiasVisitor(parentType: .simple(name: name))
    typealiasVisitor.walk(node.members)

    let propertiesVisitor = PropertySyntaxVisitor()
    propertiesVisitor.walk(node.members)

    protocolInfo = ProtocolInfo(
      name: name,
      associatedTypes: associatedtypeVisitor.associatedTypes,
      inheritsFromTypes: typeInheritanceVisitor.inheritsFromTypes,
      genericRequirements: genericRequirementVisitor.genericRequirements,
      modifiers: .init(declarationModifierVisitor.modifiers),
      innerTypealiases: typealiasVisitor.typealiases,
      properties: propertiesVisitor.propertiesInfo)

    return .skipChildren
  }

  public override func visitPost(_ node: ProtocolDeclSyntax) {
    hasFinishedParsingProtocol = true
  }

  public override func visit(_ node: StructDeclSyntax) -> SyntaxVisitorContinueKind {
    assertionFailure("Encountered a top-level struct. This is a usage error: a single ProtocolVisitor instance should start walking only over a node of type `ProtocolDeclSyntax`")
    return .skipChildren
  }

  public override func visit(_ node: ClassDeclSyntax) -> SyntaxVisitorContinueKind {
    assertionFailure("Encountered a top-level class. This is a usage error: a single ProtocolVisitor instance should start walking only over a node of type `ProtocolDeclSyntax`")
    return .skipChildren
  }

  public override func visit(_ node: EnumDeclSyntax) -> SyntaxVisitorContinueKind {
    assertionFailure("Encountered a top-level enum. This is a usage error: a single ProtocolVisitor instance should start walking only over a node of type `ProtocolDeclSyntax`")
    return .skipChildren
  }

  // MARK: Private

  private var hasFinishedParsingProtocol = false
}

public struct ProtocolInfo: Codable, Hashable {
  public let name: String
  public let associatedTypes: [AssociatedtypeInfo]
  public let inheritsFromTypes: [TypeDescription]
  public let genericRequirements: [GenericRequirement]
  public let modifiers: Set<String>
  public let innerTypealiases: [TypealiasInfo]
  public let properties: [PropertyInfo]
}
