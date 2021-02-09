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

public final class ClassVisitor: SyntaxVisitor {

  public init(parentType: TypeDescription? = nil) {
    self.parentType = parentType
  }

  deinit {
    assert(!classParsingTracker.isParsing)
  }

  /// All of the classes found by this visitor.
  public var classes: [ClassInfo] {
    [classInfo].compactMap { $0 } + innerClasses
  }

  /// Inner structs found by this visitor.
  public private(set) var innerStructs = [StructInfo]()
  /// Inner enums found by this visitor.
  public private(set) var innerEnums = [EnumInfo]()

  public override func visit(_ node: ClassDeclSyntax) -> SyntaxVisitorContinueKind {

    guard !classParsingTracker.hasFinishedParsing else {
      assertionFailure("Encountered more than one top-level class. This is a usage error: a single ClassVisitor instance should start walking only over a node of type `ClassDeclSyntax`")
      return .skipChildren
    }

    classParsingTracker.increment()

    if let classInfo = classInfo {
      // Base case. We've previously found a class declaration, so this must be an inner class.
      // This class visitor shouldn't recurse down into the children.
      // Instead, we'll use a new class visitor to get the information from this class.
      let newParentType = TypeDescription(name: classInfo.name, parent: parentType)
      let innerClassVisitor = ClassVisitor(parentType: newParentType)
      innerClassVisitor.walk(node)

      innerClasses += innerClassVisitor.classes
      // We've already gotten information from the children from our inner class visitor.
      return .skipChildren

    } else {
      // Recursive case. This is the first class declaration we've come across.
      // We need to get its information and then visit children to see if there is more information we need.
      let name = node.identifier.text
      let typeInheritanceVisitor = TypeInheritanceVisitor()
      typeInheritanceVisitor.walk(node)

      let declarationModifierVisitor = DeclarationModifierVisitor()
      if let modifiers = node.modifiers {
        declarationModifierVisitor.walk(modifiers)
      }

      classInfo = ClassInfo(
        name: name,
        inheritsFromTypes: typeInheritanceVisitor.inheritsFromTypes,
        parentType: parentType,
        modifiers: .init(declarationModifierVisitor.modifiers))
      return .visitChildren
    }
  }

  public override func visitPost(_ node: ClassDeclSyntax) {
    guard !classParsingTracker.hasFinishedParsing else { return }
    classParsingTracker.decrement()
  }

  public override func visit(_ node: StructDeclSyntax) -> SyntaxVisitorContinueKind {
    if !classParsingTracker.hasFinishedParsing, let classInfo = classInfo {
      // We've previously found a class declaration, so this must be an inner struct.
      let newParentType = TypeDescription(name: classInfo.name, parent: parentType)

      let structVisitor = StructVisitor(parentType: newParentType)
      structVisitor.walk(node)
      innerStructs += structVisitor.structs
      innerClasses += structVisitor.innerClasses
      innerEnums += structVisitor.innerEnums

    } else {
      // We've encountered a struct declaration before encountering a class declaration. Something is wrong.
      assertionFailure("Encountered a top-level struct. This is a usage error: a single ClassVisitor instance should start walking only over a node of type `ClassDeclSyntax`")
    }
    return .skipChildren
  }

  public override func visit(_ node: EnumDeclSyntax) -> SyntaxVisitorContinueKind {
    if !classParsingTracker.hasFinishedParsing, let classInfo = classInfo {
      // We've previously found a class declaration, so this must be an inner enum.
      let newParentType = TypeDescription(name: classInfo.name, parent: parentType)

      let enumVisitor = EnumVisitor(parentType: newParentType)
      enumVisitor.walk(node)
      innerEnums += enumVisitor.enums
      innerStructs += enumVisitor.innerStructs
      innerClasses += enumVisitor.innerClasses

    } else {
      // We've encountered an enum declaration before encountering a class declaration. Something is wrong.
      assertionFailure("Encountered a top-level enum. This is a usage error: a single ClassVisitor instance should start walking only over a node of type `ClassDeclSyntax`")
    }
    return .skipChildren
  }

  public override func visit(_ node: ProtocolDeclSyntax) -> SyntaxVisitorContinueKind {
    // We've encountered a protocol declaration, which can only be defined at the top-level. Something is wrong.
    assertionFailure("Encountered a protocol. This is a usage error: a single ClassVisitor instance should start walking only over a node of type `ClassDeclSyntax`")
    return .skipChildren
  }

  public override func visit(_ node: ExtensionDeclSyntax) -> SyntaxVisitorContinueKind {
    // We've encountered an extension declaration, which can only be defined at the top-level. Something is wrong.
    assertionFailure("Encountered an extension. This is a usage error: a single ClassVisitor instance should start walking only over a node of type `ClassDeclSyntax`")
    return .skipChildren
  }

  // MARK: Private

  private let parentType: TypeDescription?
  private var classParsingTracker = ParsingTracker()
  private var classInfo: ClassInfo?
  private var innerClasses = [ClassInfo]()
}

public struct ClassInfo: Codable, Equatable {
  public let name: String
  public let inheritsFromTypes: [TypeDescription]
  public let parentType: TypeDescription?
  public let modifiers: Set<String>
  // TODO: also find and expose properties on a class
}
