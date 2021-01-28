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

  public init(parentTypeName: String? = nil) {
    self.parentTypeName = parentTypeName
  }

  /// All of the structs found by this visitor.
  public var structs: [StructInfo] {
    [structInfo].compactMap { $0 } + innerStructs
  }

  // TODO: also find and nested classes
  // TODO: also find and nested enums

  public override func visit(_ node: StructDeclSyntax) -> SyntaxVisitorContinueKind {

    guard !hasFinishedParsingStruct else {
      assertionFailure("Encountered more than one top-level struct. This is a usage error: a single StructVisitor instance should start walking only over a node of type `StructDeclSyntax`")
      return .skipChildren
    }

    if let structInfo = structInfo {
      // Base case. We've previously found a struct declaration, so this must be an inner struct.
      // This struct visitor shouldn't recurse down into the children.
      // Instead, we'll use a new struct visitor to get the information from this struct.
      let qualifiedParentTypeName: String
      if let parentTypeName = parentTypeName {
        qualifiedParentTypeName = "\(parentTypeName).\(structInfo.name)"
      } else {
        qualifiedParentTypeName = structInfo.name
      }

      let innerStructVisitor = StructVisitor(parentTypeName: qualifiedParentTypeName)
      innerStructVisitor.walk(node)

      self.innerStructs += innerStructVisitor.structs
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
        parentTypeName: parentTypeName)
      return .visitChildren
    }
  }

  public override func visitPost(_ node: StructDeclSyntax) {
    hasFinishedParsingStruct = node.identifier.text == structInfo?.name
  }

  public override func visit(_ node: ClassDeclSyntax) -> SyntaxVisitorContinueKind {
    if let _ = structInfo {
      // We've previously found a struct declaration, so this must be an inner class.
      // TODO: Utilize class visitor to find inner class information, utilizing parent information from structInfo
    } else {
      // We've encountered a class declaration before encountering a struct declaration. Something is wrong.
      assertionFailure("Encountered a top-level class. This is a usage error: a single StructVisitor instance should start walking only over a node of type `StructDeclSyntax`")
    }
    return .skipChildren
  }

  public override func visit(_ node: EnumDeclSyntax) -> SyntaxVisitorContinueKind {
    if let _ = structInfo {
      // We've previously found a struct declaration, so this must be an inner enum.
      // TODO: Utilize enum visitor to find inner enum information, utilizing parent information from structInfo
    } else {
      // We've encountered a class declaration before encountering a struct declaration. Something is wrong.
      assertionFailure("Encountered a top-level enum. This is a usage error: a single StructVisitor instance should start walking only over a node of type `StructDeclSyntax`")
    }
    return .skipChildren
  }

  public override func visit(_ node: ProtocolDeclSyntax) -> SyntaxVisitorContinueKind {
    // We've encountered a protocol declaration, which can only be defined at the top-level. Something is wrong.
    assertionFailure("Encountered a protocol. This is a usage error: a single StructVisitor instance should start walking only over a node of type `StructDeclSyntax`")
    return .skipChildren
  }

  // MARK: Private

  private let parentTypeName: String?
  private var hasFinishedParsingStruct = false
  private var structInfo: StructInfo?
  private var innerStructs = [StructInfo]()
}

public struct StructInfo: Codable, Equatable {
  public let name: String
  public let inheritsFromTypes: [String]
  public let parentTypeName: String?
  // TODO: also find and expose properties on a struct
}
