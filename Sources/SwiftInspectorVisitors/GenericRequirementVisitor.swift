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

  public var genericRequirements = [GenericRequirement]()

  public override func visit(_ node: SameTypeRequirementSyntax) -> SyntaxVisitorContinueKind {
    genericRequirements.append(GenericRequirement(node: node))
    // We only care about siblings, not children.
    return .skipChildren
  }

  public override func visit(_ node: ConformanceRequirementSyntax) -> SyntaxVisitorContinueKind {
    genericRequirements.append(GenericRequirement(node: node))
    // We only care about siblings, not children.
    return .skipChildren
  }

  public override func visit(_ node: MemberDeclBlockSyntax) -> SyntaxVisitorContinueKind {
    // We don't care about the internals of a type with generic requirements.
    .skipChildren
  }
}

public struct GenericRequirement: Codable, Equatable {

  // MARK: Lifecycle

  public init(
    leftType: String,
    rightType: String,
    relationship: Relationship)
  {
    self.leftType = leftType
    self.rightType = rightType
    self.relationship = relationship
  }

  init(node: SameTypeRequirementSyntax) {
    // There is no known case where these identifiers can not be cast to SimpleTypeIdentifierSyntax.
    leftType = node.leftTypeIdentifier.as(SimpleTypeIdentifierSyntax.self)!.name.text
    rightType = node.rightTypeIdentifier.as(SimpleTypeIdentifierSyntax.self)!.name.text
    relationship = .equals
  }

  init(node: ConformanceRequirementSyntax) {
    // There is no known case where these identifiers can not be cast to SimpleTypeIdentifierSyntax.
    leftType = node.leftTypeIdentifier.as(SimpleTypeIdentifierSyntax.self)!.name.text
    rightType = node.rightTypeIdentifier.as(SimpleTypeIdentifierSyntax.self)!.name.text
    relationship = .conformsTo
  }

  // MARK: Public

  public let leftType: String
  public let rightType: String
  public let relationship: Relationship

  // MARK: - Relationship

  public enum Relationship: Int, Codable {
    case equals = 1
    case conformsTo
  }
}
