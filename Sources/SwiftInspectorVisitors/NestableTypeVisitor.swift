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

import SwiftSyntax

/// A visitor capable of parsing (possibly-nested) type information from classes, structs, and enums.
public final class NestableTypeVisitor: SyntaxVisitor {

  public init(parentType: TypeDescription? = nil) {
    self.parentType = parentType
  }

  deinit {
    assert(!topLevelParsingTracker.isParsing)
  }

  /// All the classes found by this visitor
  public var classes: [ClassInfo] {
    [topLevelDeclaration?.nestableClassInfo].compactMap { $0 } + innerClasses
  }
  /// All the structs found by this visitor
  public var structs: [StructInfo] {
    [topLevelDeclaration?.nestableStructInfo].compactMap { $0 } + innerStructs
  }
  /// All of the enums found by this visitor.
  public var enums: [EnumInfo] {
    [topLevelDeclaration?.nestableEnumInfo].compactMap { $0 } + innerEnums
  }

  /// Typealiases declarations found by this visitor.
  public private(set) var typealiases = [TypealiasInfo]()

  public override func visit(_ node: ClassDeclSyntax) -> SyntaxVisitorContinueKind {
    visitNestableDeclaration(node: node, topLevelDeclarationCreator: { .topLevelClass($0) })
  }

  public override func visitPost(_ node: ClassDeclSyntax) {
    decrementParsingTracker()
  }

  public override func visit(_ node: StructDeclSyntax) -> SyntaxVisitorContinueKind {
    visitNestableDeclaration(node: node, topLevelDeclarationCreator: { .topLevelStruct($0) })
  }

  public override func visitPost(_ node: StructDeclSyntax) {
    decrementParsingTracker()
  }

  public override func visit(_ node: EnumDeclSyntax) -> SyntaxVisitorContinueKind {
    visitNestableDeclaration(node: node, topLevelDeclarationCreator: { .topLevelEnum($0) })
  }

  public override func visitPost(_ node: EnumDeclSyntax) {
    decrementParsingTracker()
  }

  public override func visit(_ node: ProtocolDeclSyntax) -> SyntaxVisitorContinueKind {
    // We've encountered a protocol declaration, which can only be defined at the top-level. Something is wrong.
    assertionFailureOrPostNotification("Encountered a protocol. This is a usage error: a single NestableTypeVisitor instance should start walking only over a nestable declaration syntax node")
    return .skipChildren
  }

  public override func visit(_ node: ExtensionDeclSyntax) -> SyntaxVisitorContinueKind {
    // We've encountered an extension declaration, which can only be defined at the top-level. Something is wrong.
    assertionFailureOrPostNotification("Encountered an extension. This is a usage error: a single NestableTypeVisitor instance should start walking only over a nestable declaration syntax node")
    return .skipChildren
  }

  public override func visit(_ node: TypealiasDeclSyntax) -> SyntaxVisitorContinueKind {
    guard
      !topLevelParsingTracker.hasFinishedParsing,
      let topLevelDeclarationName = topLevelDeclaration?.nestableInfo.name
    else {
      assertionFailureOrPostNotification("Encountered more than one top-level declaration. This is a usage error: a single NestableTypeVisitor instance should start walking only over a declaration syntax node")
      return .skipChildren
    }

    // We've previously found a top-level declaration, so this must be an inner declaration.
    let newParentType = TypeDescription(name: topLevelDeclarationName, parent: parentType)
    let typealiasVisitor = TypealiasVisitor(parentType: newParentType)
    typealiasVisitor.walk(node)
    typealiases.append(contentsOf: typealiasVisitor.typealiases)

    // We don't need to visit children because our visitor just did that for us.
    return .skipChildren
  }

  // MARK: Private

  private func visitNestableDeclaration<DeclSyntax: NestableDeclSyntax>(
    node: DeclSyntax,
    topLevelDeclarationCreator: (NestableTypeInfo) -> TopLevelDeclaration)
  -> SyntaxVisitorContinueKind
  {
    guard !topLevelParsingTracker.hasFinishedParsing else {
      assertionFailureOrPostNotification("Encountered more than one top-level declaration. This is a usage error: a single NestableTypeVisitor instance should start walking only over a declaration syntax node")
      return .skipChildren
    }

    topLevelParsingTracker.increment()

    if !topLevelParsingTracker.hasFinishedParsing, let topLevelDeclarationName = topLevelDeclaration?.nestableInfo.name {
      // Base case. We've previously found a top-level declaration, so this must be an inner declaration.
      // This visitor shouldn't recurse down into the children.
      // Instead, we'll use a new visitor to get the information from this declaration.
      let newParentType = TypeDescription(name: topLevelDeclarationName, parent: parentType)
      let declarationVisitor = NestableTypeVisitor(parentType: newParentType)
      declarationVisitor.walk(node)

      innerEnums += declarationVisitor.enums
      innerClasses += declarationVisitor.classes
      innerStructs += declarationVisitor.structs
      typealiases += declarationVisitor.typealiases

      // We've already gotten information from the children from our inner visitor.
      return .skipChildren

    } else {
      // Recursive case. This is the first top-level declaration we've come across.
      // We need to get its information and then visit children to see if there is more information we need.
      let typeInheritanceVisitor = TypeInheritanceVisitor()
      if let inheritanceClause = node.inheritanceClause {
        typeInheritanceVisitor.walk(inheritanceClause)
      }

      let declarationModifierVisitor = DeclarationModifierVisitor()
      if let modifiers = node.modifiers {
        declarationModifierVisitor.walk(modifiers)
      }

      let genericParameterVisitor = GenericParameterVisitor()
      if let genericParameterClause = node.genericParameterClause {
        genericParameterVisitor.walk(genericParameterClause)
      }

      let genericRequirementVisitor = GenericRequirementVisitor()
      if let genericWhereClause = node.genericWhereClause {
        genericRequirementVisitor.walk(genericWhereClause)
      }

      let visitor = FunctionDeclarationVisitor()
      visitor.walk(node.members)
      let functionDeclarations = visitor.functionDeclarations

      let propertyVisitor = PropertyVisitor()
      propertyVisitor.walk(node.members)

      topLevelDeclaration = topLevelDeclarationCreator(
        .init(
          name: node.identifier.text,
          inheritsFromTypes: typeInheritanceVisitor.inheritsFromTypes,
          parentType: parentType,
          modifiers: Set(declarationModifierVisitor.modifiers),
          genericParameters: genericParameterVisitor.genericParameters,
          genericRequirements: genericRequirementVisitor.genericRequirements,
          properties: propertyVisitor.properties,
          functionDeclarations: functionDeclarations))

      return .visitChildren
    }
  }

  private func decrementParsingTracker() {
    guard !topLevelParsingTracker.hasFinishedParsing else { return }
    topLevelParsingTracker.decrement()
  }

  private let parentType: TypeDescription?
  private var topLevelParsingTracker = ParsingTracker()
  private var topLevelDeclaration: TopLevelDeclaration?
  private var innerEnums = [EnumInfo]()
  private var innerStructs = [StructInfo]()
  private var innerClasses = [ClassInfo]()
}

private enum TopLevelDeclaration {
  case topLevelClass(ClassInfo)
  case topLevelStruct(StructInfo)
  case topLevelEnum(EnumInfo)

  var nestableInfo: NestableTypeInfo {
    switch self {
    case let .topLevelClass(topLevelObject),
         let .topLevelEnum(topLevelObject),
         let .topLevelStruct(topLevelObject):
      return topLevelObject
    }
  }

  var nestableClassInfo: ClassInfo? {
    switch self {
    case let .topLevelClass(topLevelObject):
      return topLevelObject
    case .topLevelStruct,
         .topLevelEnum:
      return nil
    }
  }

  var nestableStructInfo: StructInfo? {
    switch self {
    case let .topLevelStruct(topLevelObject):
      return topLevelObject
    case .topLevelClass,
         .topLevelEnum:
      return nil
    }
  }

  var nestableEnumInfo: EnumInfo? {
    switch self {
    case let .topLevelEnum(topLevelObject):
      return topLevelObject
    case .topLevelClass,
         .topLevelStruct:
      return nil
    }
  }
}
