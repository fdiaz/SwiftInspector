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

  public var protocolInfo: ProtocolInfo? {
    guard let name = name else { return nil }
    return ProtocolInfo(
      name: name,
      associatedTypes: associatedtypes,
      inheritsFromTypes: inheritsFromTypes ?? [],
      genericRequirements: genericRequirements ?? [],
      modifiers: modifiers ?? .init(),
      innerTypealiases: typealiases,
      properties: properties)
  }

  public override func visit(_ node: ProtocolDeclSyntax) -> SyntaxVisitorContinueKind {

    guard !hasFinishedParsingProtocol else {
      assertionFailure("Encountered more than one top-level protocol. This is a usage error: a single ProtocolVisitor instance should start walking only over a node of type `ProtocolDeclSyntax`")
      return .skipChildren
    }
    let name = node.identifier.text
    self.name = name
    parentType = .simple(name: name)

    let typeInheritanceVisitor = TypeInheritanceVisitor()
    if let inheritanceClause = node.inheritanceClause {
      typeInheritanceVisitor.walk(inheritanceClause)
      inheritsFromTypes = typeInheritanceVisitor.inheritsFromTypes
    }
    let genericRequirementVisitor = GenericRequirementVisitor()
    if let genericWhereClause = node.genericWhereClause {
      genericRequirementVisitor.walk(genericWhereClause)
      genericRequirements = genericRequirementVisitor.genericRequirements
    }

    let declarationModifierVisitor = DeclarationModifierVisitor()
    if let modifiers = node.modifiers {
      declarationModifierVisitor.walk(modifiers)
      self.modifiers = .init(declarationModifierVisitor.modifiers)
    }

    return .visitChildren
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

  public override func visit(_ node: AssociatedtypeDeclSyntax) -> SyntaxVisitorContinueKind {
    let associatedtypeVisitor = AssociatedtypeVisitor()
    associatedtypeVisitor.walk(node)
    associatedtypes.append(contentsOf: associatedtypeVisitor.associatedTypes)

    // We don't need to visit children because our visitor just did that for us.
    return .skipChildren

  }

  public override func visit(_ node: TypealiasDeclSyntax) -> SyntaxVisitorContinueKind {
    let typealiasVisitor = TypealiasVisitor(parentType: parentType)
    typealiasVisitor.walk(node)
    typealiases.append(contentsOf: typealiasVisitor.typealiases)

    // We don't need to visit children because our visitor just did that for us.
    return .skipChildren
  }

  public override func visit(_ node: VariableDeclSyntax) -> SyntaxVisitorContinueKind {
    let propertiesVisitor = PropertyVisitor()
    propertiesVisitor.walk(node)
    properties.append(contentsOf: propertiesVisitor.properties)

    // We don't need to visit children because our visitor just did that for us.
    return .skipChildren
  }

  // MARK: Private

  private var hasFinishedParsingProtocol = false
  private var name: String?
  private var modifiers: Set<String>?
  private var inheritsFromTypes: [TypeDescription]?
  private var genericRequirements: [GenericRequirement]?
  private var associatedtypes: [AssociatedtypeInfo] = []
  private var typealiases: [TypealiasInfo] = []
  private var properties: [PropertyInfo] = []
  private var parentType: TypeDescription?
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
