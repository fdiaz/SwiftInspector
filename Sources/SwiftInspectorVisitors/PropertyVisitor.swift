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
    .skipChildren
  }

  public override func visit(_ node: StructDeclSyntax) -> SyntaxVisitorContinueKind {
    .skipChildren
  }

  public override func visit(_ node: EnumDeclSyntax) -> SyntaxVisitorContinueKind {
    .skipChildren
  }

  public override func visit(_ node: ProtocolDeclSyntax) -> SyntaxVisitorContinueKind {
    .skipChildren
  }

  public override func visit(_ node: ExtensionDeclSyntax) -> SyntaxVisitorContinueKind {
    .skipChildren
  }

  // MARK: Private

  private enum PropertyType: String {
    case constant = "let"
    case variable = "var"
  }

  private func findModifiers(from node: VariableDeclSyntax) -> PropertyInfo.Modifier {
    let modifiersString: [String]
    if let modifiersSyntaxList = node.modifiers {
      modifiersString = modifiersSyntaxList.children
        .compactMap { $0.as(DeclModifierSyntax.self) }
        .map { modifierSyntax in
          if
            let leftParen = modifierSyntax.detailLeftParen,
            let detail = modifierSyntax.detail,
            let rightParen = modifierSyntax.detailRightParen
          {
            return modifierSyntax.name.text + leftParen.text + detail.text + rightParen.text
          }
          return modifierSyntax.name.text
        }
    }
    else {
      modifiersString = []
    }

    var modifier = modifiersString.reduce(PropertyInfo.Modifier()) { result, stringValue in
      let modifier = PropertyInfo.Modifier(stringValue: stringValue)
      return result.union(modifier)
    }

    // If there are no explicit modifiers, this is an internal property
    if !modifier.contains(.open) &&
        !modifier.contains(.public) &&
        !modifier.contains(.fileprivate) &&
        !modifier.contains(.private)
    {
      modifier = modifier.union(.internal)
    }

    // If the variable isn't static, it's an instance variable
    if !modifier.contains(.static) {
      modifier = modifier.union(.instance)
    }

    return modifier
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
    switch findPropertyType(from: node) {
    case .constant:
      if let initializerDescription = findInitializerDescription(from: node.bindings) {
        return .definedConstant(initializerDescription)
      }
      else {
        return .undefinedConstant
      }
    case .variable:
      if let initializerDescription = findInitializerDescription(from: node.bindings) {
        return .definedVariable(initializerDescription)
      }
      else if let codeBlockDescription = findCodeBlockDescription(from: node.bindings) {
        return .computedVariable(codeBlockDescription)
      }
      else {
        return .undefinedVariable
      }
    }
  }

  private func findInitializerDescription(from node: PatternBindingListSyntax) -> String? {
    let initializerClauseSyntaxes = node.compactMap { $0.initializer?.withEqual(nil) }
    assert(initializerClauseSyntaxes.count <= 1, "A property should have at most one initializer.")
    return initializerClauseSyntaxes.first?.description
  }

  private func findCodeBlockDescription(from node: PatternBindingListSyntax) -> String? {
    guard
      let patternBindingSyntax = node.children.first?.as(PatternBindingSyntax.self),
      let codeBlockSyntax = patternBindingSyntax.children.compactMap({ $0.as(CodeBlockSyntax.self) }).first,
      let codeBlockList = codeBlockSyntax.children
        .compactMap ({ $0.as(CodeBlockItemListSyntax.self) })
        .first
    else {
      return nil
    }
    return codeBlockList.withoutTrivia().description
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
