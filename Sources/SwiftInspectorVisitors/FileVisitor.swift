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

public final class FileVisitor: SyntaxVisitor {

  public init(fileURL: URL) {
    fileInfo = FileInfo(url: fileURL)
  }

  public private(set) var fileInfo: FileInfo

  public override func visit(_ node: ImportDeclSyntax) -> SyntaxVisitorContinueKind {
    let importVisitor = ImportVisitor()
    importVisitor.walk(node)

    fileInfo.appendImports(importVisitor.imports)

    // We don't need to visit children because our visitor just did that for us.
    return .skipChildren
  }
  public override func visit(_ node: ProtocolDeclSyntax) -> SyntaxVisitorContinueKind {
    let protocolVisitor = ProtocolVisitor()
    protocolVisitor.walk(node)

    if let protocolInfo = protocolVisitor.protocolInfo {
      fileInfo.appendProtocol(protocolInfo)
      fileInfo.appendTypealiases(protocolInfo.innerTypealiases)
    }

    // We don't need to visit children because our visitor just did that for us.
    return .skipChildren
  }

  public override func visit(_ node: StructDeclSyntax) -> SyntaxVisitorContinueKind {
    visitNestableDeclaration(node: node)
  }

  public override func visit(_ node: ClassDeclSyntax) -> SyntaxVisitorContinueKind {
    visitNestableDeclaration(node: node)
  }

  public override func visit(_ node: EnumDeclSyntax) -> SyntaxVisitorContinueKind {
    visitNestableDeclaration(node: node)
  }

  public override func visit(_ node: ExtensionDeclSyntax) -> SyntaxVisitorContinueKind {
    let extensionVisitor = ExtensionVisitor()
    extensionVisitor.walk(node)

    if let extensionInfo = extensionVisitor.extensionInfo {
      fileInfo.appendExtension(extensionInfo)
      fileInfo.appendEnums(extensionVisitor.innerEnums)
      fileInfo.appendClasses(extensionVisitor.innerClasses)
      fileInfo.appendStructs(extensionVisitor.innerStructs)
      fileInfo.appendTypealiases(extensionVisitor.innerTypealiases)
    }

    // We don't need to visit children because our visitor just did that for us.
    return .skipChildren
  }

  public override func visit(_ node: TypealiasDeclSyntax) -> SyntaxVisitorContinueKind {
    let typealiasVisitor = TypealiasVisitor()
    typealiasVisitor.walk(node)

    fileInfo.appendTypealiases(typealiasVisitor.typealiases)

    // We don't need to visit children because our visitor just did that for us.
    return .skipChildren
  }

  // MARK: Private

  private func visitNestableDeclaration<DeclSyntax: NestableDeclSyntax>(node: DeclSyntax) -> SyntaxVisitorContinueKind {
    let declarationVisitor = NestableTypeVisitor()
    declarationVisitor.walk(node)

    fileInfo.appendStructs(declarationVisitor.structs)
    fileInfo.appendClasses(declarationVisitor.classes)
    fileInfo.appendEnums(declarationVisitor.enums)
    fileInfo.appendTypealiases(declarationVisitor.typealiases)

    // We don't need to visit children because our visitor just did that for us.
    return .skipChildren
  }

}

public struct FileInfo: Codable, Hashable {
  public let url: URL
  public private(set) var imports = [ImportStatement]()
  public private(set) var protocols = [ProtocolInfo]()
  public private(set) var structs = [StructInfo]()
  public private(set) var classes = [ClassInfo]()
  public private(set) var enums = [EnumInfo]()
  public private(set) var extensions = [ExtensionInfo]()
  public private(set) var typealiases = [TypealiasInfo]()

  mutating func appendImports(_ imports: [ImportStatement]) {
    self.imports += imports
  }
  mutating func appendProtocol(_ protocolInfo: ProtocolInfo) {
    protocols.append(protocolInfo)
  }
  mutating func appendStructs(_ structs: [StructInfo]) {
    self.structs += structs
  }
  mutating func appendClasses(_ classes: [ClassInfo]) {
    self.classes += classes
  }
  mutating func appendEnums(_ enums: [EnumInfo]) {
    self.enums += enums
  }
  mutating func appendExtension(_ extensionInfo: ExtensionInfo) {
    extensions.append(extensionInfo)
  }
  mutating func appendTypealiases(_ typealiases: [TypealiasInfo]) {
    self.typealiases += typealiases
  }
}
