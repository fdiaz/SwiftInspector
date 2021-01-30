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
  public private(set) var structs = [StructInfo]()

  // TODO: also find and nested classes
  // TODO: also find and nested enums

  public override func visit(_ node: ExtensionDeclSyntax) -> SyntaxVisitorContinueKind {

    guard !hasFinishedParsingExtension else {
      assertionFailure("Encountered more than one top-level extension. This is a usage error: a single ExtensionVisitor instance should start walking only over a node of type `ExtensionDeclSyntax`")
      return .skipChildren
    }

    // There is no known case where these identifiers can not be cast to SimpleTypeIdentifierSyntax.
    let name = node.extendedType.as(SimpleTypeIdentifierSyntax.self)!.name.text
    let typeInheritanceVisitor = TypeInheritanceVisitor()
    typeInheritanceVisitor.walk(node)
    let genericRequirementsVisitor = GenericRequirementVisitor()
    genericRequirementsVisitor.walk(node)

    extensionInfo = ExtensionInfo(
      name: name,
      inheritsFromTypes: typeInheritanceVisitor.inheritsFromTypes,
      genericRequirements: genericRequirementsVisitor.genericRequirements,
      innerStructs: [])
    return .visitChildren
  }

  public override func visitPost(_ node: ExtensionDeclSyntax) {
    hasFinishedParsingExtension = true
  }

  public override func visit(_ node: ClassDeclSyntax) -> SyntaxVisitorContinueKind {
    if !hasFinishedParsingExtension, let _ = extensionInfo {
      // We've previously found an extension declaration, so this must be an inner class.
      // TODO: Utilize class visitor to find inner class information, utilizing parent information from extensionInfo
    } else {
      // We've encountered a class declaration before encountering an extension declaration. Something is wrong.
      assertionFailure("Encountered a top-level class. This is a usage error: a single ExtensionVisitor instance should start walking only over a node of type `ExtensionDeclSyntax`")
    }
    return .skipChildren
  }

  public override func visit(_ node: StructDeclSyntax) -> SyntaxVisitorContinueKind {
    if !hasFinishedParsingExtension, let extensionInfo = extensionInfo {
      // We've previously found an extension declaration, so this must be an inner struct.
      let structVisitor = StructVisitor(parentTypeName: extensionInfo.name)
      structVisitor.walk(node)

      structs.append(contentsOf: structVisitor.structs)

    } else {
      // We've encountered a class declaration before encountering an extension declaration. Something is wrong.
      assertionFailure("Encountered a top-level struct. This is a usage error: a single ExtensionVisitor instance should start walking only over a node of type `ExtensionDeclSyntax`")
    }

    return .skipChildren
  }

  public override func visit(_ node: EnumDeclSyntax) -> SyntaxVisitorContinueKind {
    if !hasFinishedParsingExtension, let _ = extensionInfo {
      // We've previously found a extension declaration, so this must be an inner enum.
      // TODO: Utilize enum visitor to find inner enum information, utilizing parent information from extensionInfo
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
  public let name: String
  public private(set) var inheritsFromTypes: [String]
  public private(set) var genericRequirements: [GenericRequirement]
  public private(set) var innerStructs: [StructInfo]
  // TODO: Also find and expose inner classes
  // TODO: Also find and expose inner enums
  // TODO: also find and expose computed properties
}