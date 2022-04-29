// Created by Dan Federman on 2/17/21.
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

public final class TypealiasVisitor: SyntaxVisitor {

  public init(parentType: TypeDescription? = nil) {
    self.parentType = parentType
  }

  public private(set) var typealiases = [TypealiasInfo]()

  public override func visit(_ node: TypealiasDeclSyntax) -> SyntaxVisitorContinueKind {
    let name = node.identifier.text

    let genericTypeVisitor = GenericParameterVisitor()
    if let genericParameterClause = node.genericParameterClause {
      genericTypeVisitor.walk(genericParameterClause)
    }

    let genericRequirementVisitor = GenericRequirementVisitor()
    if let genericWhereClause = node.genericWhereClause {
      genericRequirementVisitor.walk(genericWhereClause)
    }

    let declarationModifierVisitor = DeclarationModifierVisitor()
    if let modifiers = node.modifiers {
      declarationModifierVisitor.walk(modifiers)
    }

    typealiases.append(
      .init(
        name: name,
        genericParameters: genericTypeVisitor.genericParameters,
        initializer: node.initializer?.value.typeDescription,
        genericRequirements: genericRequirementVisitor.genericRequirements,
        modifiers: declarationModifierVisitor.modifiers,
        parentType: parentType))

    return .skipChildren
  }

  // MARK: Private

  private let parentType: TypeDescription?
}

public struct TypealiasInfo: Codable, Hashable {
  public let name: String
  public let genericParameters: [GenericParameter]
  public let initializer: TypeDescription?
  public let genericRequirements: [GenericRequirement]
  public let modifiers: Modifiers
  public let parentType: TypeDescription?
}
