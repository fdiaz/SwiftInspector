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
    }

    // We don't need to visit children because our visitor just did that for us.
    return .skipChildren
  }

  public override func visit(_ node: StructDeclSyntax) -> SyntaxVisitorContinueKind {
    let structVisitor = StructVisitor()
    structVisitor.walk(node)

    fileInfo.appendStructs(structVisitor.structs)
    fileInfo.appendClasses(structVisitor.innerClasses)
    // TODO: append enums

    // We don't need to visit children because our visitor just did that for us.
    return .skipChildren
  }

  public override func visit(_ node: ClassDeclSyntax) -> SyntaxVisitorContinueKind {
    let classVisitor = ClassVisitor()
    classVisitor.walk(node)

    fileInfo.appendClasses(classVisitor.classes)
    fileInfo.appendStructs(classVisitor.innerStructs)
    // TODO: append enums

    // We don't need to visit children because our visitor just did that for us.
    return .skipChildren
  }

  public override func visit(_ node: EnumDeclSyntax) -> SyntaxVisitorContinueKind {
    // TODO: find an append enums
    // TODO: append structs
    // TODO: append classes

    // We don't need to visit children because our visitor just did that for us.
    return .skipChildren
  }
}

public struct FileInfo: Codable, Equatable {
  public let url: URL
  public private(set) var imports = [ImportStatement]()
  public private(set) var protocols = [ProtocolInfo]()
  public private(set) var structs = [StructInfo]()
  public private(set) var classes = [ClassInfo]()
  // TODO: also find enums

  mutating func appendImports(_ imports: [ImportStatement]) {
    self.imports.append(contentsOf: imports)
  }
  mutating func appendProtocol(_ protocolInfo: ProtocolInfo) {
    protocols.append(protocolInfo)
  }
  mutating func appendStructs(_ structs: [StructInfo]) {
    self.structs.append(contentsOf: structs)
  }
  mutating func appendClasses(_ classes: [ClassInfo]) {
    self.classes.append(contentsOf: classes)
  }
}
