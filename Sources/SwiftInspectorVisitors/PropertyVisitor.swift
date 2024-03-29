// Created by francisco_diaz on 7/7/21.
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

// MARK: - PropertyVisitor

public final class PropertyVisitor: SyntaxVisitor {

  /// Information about each of the properties found on the type.
  private(set) var properties: [PropertyInfo] = []

  public override func visit(_ node: VariableDeclSyntax) -> SyntaxVisitorContinueKind {
    let modifier = findModifiers(from: node)
    let paradigm = findParadigm(from: node)

    var lastFoundType: TypeDescription?
    node.bindings.reversed().forEach { binding in
      if let identifier = binding.pattern.as(IdentifierPatternSyntax.self) {
        let typeName = findTypeDescription(from: binding.typeAnnotation)
        // If we find a type name on the n element, but n-1 doesn't have an explicit type name, n-1 has the same type as n
        // e.g. let red: Int, green, blue: Double
        // where both green and blue are of type Double
        if let typeName = typeName { lastFoundType = typeName }
        properties.append(.init(
                            name: identifier.identifier.text,
                            typeDescription: lastFoundType,
                            modifiers: modifier,
                            paradigm: paradigm))
      }
    }

    return .skipChildren
  }

  public override func visit(_ node: ClassDeclSyntax) -> SyntaxVisitorContinueKind {
    assertionFailureOrPostNotification("Encountered a class declaration. This is a usage error: a single PropertyVisitor instance should start walking only over a property declaration node")
    return .skipChildren
  }

  public override func visit(_ node: StructDeclSyntax) -> SyntaxVisitorContinueKind {
    assertionFailureOrPostNotification("Encountered a struct declaration. This is a usage error: a single PropertyVisitor instance should start walking only over a property declaration node")
    return .skipChildren
  }

  public override func visit(_ node: EnumDeclSyntax) -> SyntaxVisitorContinueKind {
    assertionFailureOrPostNotification("Encountered an enum declaration. This is a usage error: a single PropertyVisitor instance should start walking only over a property declaration node")
    return .skipChildren
  }

  public override func visit(_ node: ProtocolDeclSyntax) -> SyntaxVisitorContinueKind {
    assertionFailureOrPostNotification("Encountered a protocol declaration. This is a usage error: a single PropertyVisitor instance should start walking only over a property declaration node")
    return .skipChildren
  }

  public override func visit(_ node: ExtensionDeclSyntax) -> SyntaxVisitorContinueKind {
    assertionFailureOrPostNotification("Encountered an extension declaration. This is a usage error: a single PropertyVisitor instance should start walking only over a property declaration node")
    return .skipChildren
  }

  // MARK: Private

  private enum PropertyType: String {
    case constant = "let"
    case variable = "var"
  }

  private func findModifiers(from node: VariableDeclSyntax) -> Modifiers {
    let modifiersVisitor = DeclarationModifierVisitor()
    if let modifiers = node.modifiers {
      modifiersVisitor.walk(modifiers)
    }

    var modifiers = modifiersVisitor.modifiers

    // If there are no explicit modifiers, this is an internal property
    if !modifiers.contains(.open) &&
        !modifiers.contains(.public) &&
        !modifiers.contains(.fileprivate) &&
        !modifiers.contains(.private)
    {
      modifiers = modifiers.union(.internal)
    }

    // If the variable isn't static, it's an instance variable
    if !modifiers.contains(.static) {
      modifiers = modifiers.union(.instance)
    }

    return modifiers
  }

  private func findTypeDescription(from node: TypeAnnotationSyntax?) -> TypeDescription? {
    guard
      let typeAnnotation = node,
      let typeSyntax = typeAnnotation.type.as(TypeSyntax.self) else {
      // No type annotation was found.
      // e.g.:
      // public let thing: String = "Hello" has a type annotation, String which makes this easy
      // public let thing = "Hello" does not have a type annotation.
      return nil
    }
    return typeSyntax.typeDescription
  }

  private func findParadigm(from node: VariableDeclSyntax) -> PropertyInfo.Paradigm {
    let patternBindingListVisitor = PatternBindingListVisitor()
    patternBindingListVisitor.walk(node.bindings)

    assert(
      patternBindingListVisitor.validateExtractedData(), "The data extracted from the pattern binding does not match our expectations")

    switch findPropertyType(from: node) {
    case .constant:
      if let initializerDescription = patternBindingListVisitor.initializerDescription {
        return .definedConstant(initializerDescription)
      }
      else {
        return .undefinedConstant
      }
    case .variable:
      if let initializerDescription = patternBindingListVisitor.initializerDescription {
        return .definedVariable(initializerDescription)
      }
      else if let codeBlockDescription = patternBindingListVisitor.codeBlockDescription {
        return .computedVariable(codeBlockDescription)
      }
      else if patternBindingListVisitor.protocolRequirements == .gettableAndSettable {
        return .protocolGetterAndSetter
      }
      else if patternBindingListVisitor.protocolRequirements == .gettable {
        return .protocolGetter
      }
      // It is not possible for a property in a protocol to only be settable.
      else {
        return .undefinedVariable
      }
    }
  }

  private func findPropertyType(from node: VariableDeclSyntax) -> PropertyType {
    if let type = PropertyType(rawValue: node.letOrVarKeyword.text) {
      return type
    }
    else {
      assertionFailure("Property must be either let or var. The Swift language has evolved if you hit this assertion.")
      // Fail gracefully
      return .variable
    }
  }
}

// MARK: - PatternBindingListVisitor

private final class PatternBindingListVisitor: SyntaxVisitor {

  struct ProtocolRequirements: OptionSet {
    let rawValue: Int

    static let gettable = ProtocolRequirements(rawValue: 1 << 0)
    static let settable = ProtocolRequirements(rawValue: 1 << 1)

    static let gettableAndSettable: ProtocolRequirements = [.gettable, .settable]
  }

  /// A source-accurate description of the code block for a computed property, if one exists. Outer `{` and `}` are not included.
  private(set) var codeBlockDescription: String?
  /// A source-accurate description of initializer clause of a property. The `=` is not included.
  private(set) var initializerDescription: String?
  /// The protocol requirements for this property.
  private(set) var protocolRequirements: ProtocolRequirements = []

  public override func visit(_ node: CodeBlockItemListSyntax) -> SyntaxVisitorContinueKind {
    codeBlockDescription = node.withoutTrivia().description
    return .skipChildren
  }

  public override func visit(_ node: InitializerClauseSyntax) -> SyntaxVisitorContinueKind {
    initializerDescription = node.withEqual(nil).description
    return .skipChildren
  }

  public override func visit(_ node: AccessorDeclSyntax) -> SyntaxVisitorContinueKind {
    if node.accessorKind.text == "get" { protocolRequirements.insert(.gettable) }
    if node.accessorKind.text == "set" { protocolRequirements.insert(.settable) }
    return .skipChildren
  }

  /// Return `true` if the extracted data matches our expectations; otherwise, returns `false`.
  func validateExtractedData() -> Bool {
    // We expect only one of these to be present.
    let isPresentForExtractedElements: [Bool] = [
      initializerDescription != nil,
      codeBlockDescription != nil,
      !protocolRequirements.isEmpty,
    ]
    return isPresentForExtractedElements.filter { $0 }.count <= 1
  }
}
