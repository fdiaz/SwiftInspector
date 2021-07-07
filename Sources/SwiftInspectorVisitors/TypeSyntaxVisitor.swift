// Created by Michael Bachand on 4/8/21.
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

// MARK: - TypeSyntaxVisitor

/// Finds all properties associated with a type name. Since this visitor does not have access to a fully qualfied type name, the resulting
/// properties may be associated with more than one distinct type.
public final class TypeSyntaxVisitor: SyntaxVisitor {

  // MARK: Lifecycle

  public init(typeName: String) {
    self.typeName = typeName
  }

  // MARK: Public

  /// Information about each of the properties found on the type. `nil` if the type is not found.
  public private(set) var propertiesData: Set<PropertyData>?

  public override func visit(_ node: ClassDeclSyntax) -> SyntaxVisitorContinueKind {
    if node.identifier.text == typeName {
      processNode(node, members: node.members.members)
    }
    return .visitChildren
  }

  public override func visit(_ node: EnumDeclSyntax) -> SyntaxVisitorContinueKind {
    if node.identifier.text == typeName {
      processNode(node, members: node.members.members)
    }
    return .visitChildren
  }

  public override func visit(_ node: ProtocolDeclSyntax) -> SyntaxVisitorContinueKind {
    if node.identifier.text == typeName {
      processNode(node, members: node.members.members)
    }
    return .visitChildren
  }

  public override func visit(_ node: StructDeclSyntax) -> SyntaxVisitorContinueKind {
    if node.identifier.text == typeName {
      processNode(node, members: node.members.members)
    }
    return .visitChildren
  }

  public override func visit(_ node: ExtensionDeclSyntax) -> SyntaxVisitorContinueKind {
    if
      let typeIdentifier = node.extendedType.as(SimpleTypeIdentifierSyntax.self),
      typeIdentifier.name.text == typeName
    {
      processNode(node, members: node.members.members)
    }
    return .visitChildren
  }

  // MARK: Internal

  /// Merges the new property data with property data we've already found.
  static func merge(
    _ newPropertiesData: Set<PropertyData>,
    into existingPropertiesData: Set<PropertyData>?)
  -> Set<PropertyData>
  {
    if let existingPropertiesData = existingPropertiesData {
      return newPropertiesData.union(existingPropertiesData)
    }
    else {
      return newPropertiesData
    }
  }

  // MARK: Private

  private let typeName: String

  private func processNode<Node>(_ node: Node, members: MemberDeclListSyntax) where Node: SyntaxProtocol {
    let propertyVisitor = PropertySyntaxVisitor()
    propertyVisitor.walk(node)
    propertiesData = Self.merge(propertyVisitor.propertiesData, into: propertiesData)
  }
}
