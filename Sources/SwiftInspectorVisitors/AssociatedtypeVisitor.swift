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

public final class AssociatedtypeVisitor: SyntaxVisitor {

  public private(set) var associatedTypes = [AssociatedtypeInfo]()

  public override func visit(_ node: AssociatedtypeDeclSyntax) -> SyntaxVisitorContinueKind {
    let name = node.identifier.text

    let typeInheritanceVisitor = TypeInheritanceVisitor()
    if let inheritanceClause = node.inheritanceClause {
      typeInheritanceVisitor.walk(inheritanceClause)
    }

    let genericRequirementsVisitor = GenericRequirementVisitor()
    if let genericWhereClause = node.genericWhereClause {
      genericRequirementsVisitor.walk(genericWhereClause)
    }

    associatedTypes.append(
      .init(
        name: name,
        inheritsFromTypes: typeInheritanceVisitor.inheritsFromTypes,
        initializer: node.initializer?.value.typeDescription,
        genericRequirements: genericRequirementsVisitor.genericRequirements))

    return .skipChildren
  }
}

public struct AssociatedtypeInfo: Codable, Hashable {
  public let name: String
  public let inheritsFromTypes: [TypeDescription]
  public let initializer: TypeDescription?
  public let genericRequirements: [GenericRequirement]
}
