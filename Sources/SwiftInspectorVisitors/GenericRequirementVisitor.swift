// Created by Dan Federman on 1/26/21.
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

public final class GenericRequirementVisitor: SyntaxVisitor {

  public private(set) var genericRequirements = [GenericRequirement]()

  public override func visit(_ node: SameTypeRequirementSyntax) -> SyntaxVisitorContinueKind {
    genericRequirements.append(GenericRequirement(node: node))
    // Children don't have any more information about generic requirements, so don't visit them.
    return .skipChildren
  }

  public override func visit(_ node: ConformanceRequirementSyntax) -> SyntaxVisitorContinueKind {
    genericRequirements.append(GenericRequirement(node: node))
    // Children don't have any more information about generic requirements, so don't visit them.
    return .skipChildren
  }

  public override func visit(_ node: MemberDeclBlockSyntax) -> SyntaxVisitorContinueKind {
    // A member declaration block means we've found the body of the type.
    // There's nothing in this body that would help us determine generic requirements.
    .skipChildren
  }
}

public struct GenericRequirement: Codable, Equatable {

  // MARK: Lifecycle

  init(node: SameTypeRequirementSyntax) {
    leftType = node.leftTypeIdentifier.typeDescription
    rightType = node.rightTypeIdentifier.typeDescription
    relationship = .equals
  }

  init(node: ConformanceRequirementSyntax) {
    leftType = node.leftTypeIdentifier.typeDescription
    rightType = node.rightTypeIdentifier.typeDescription
    relationship = .conformsTo
  }

  // MARK: Public

  public let leftType: TypeDescription
  public let rightType: TypeDescription
  public let relationship: Relationship

  // MARK: - Relationship

  public enum Relationship: Int, Codable {
    case equals = 1
    case conformsTo
  }
}
