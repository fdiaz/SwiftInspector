// Created by Francisco Diaz on 10/14/19.
//
// Copyright (c) 2020 Francisco Diaz
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

public final class ImportVisitor: SyntaxVisitor {
  public private(set) var imports: [ImportStatement] = []

  public override func visit(_ node: ImportDeclSyntax) -> SyntaxVisitorContinueKind {
    let statement = importStatement(from: node)
    imports.append(statement)
    return .visitChildren
  }

  public override func visit(_ node: ProtocolDeclSyntax) -> SyntaxVisitorContinueKind {
    // We don't need to visit children because this code can't have imports.
    return .skipChildren
  }

  public override func visit(_ node: StructDeclSyntax) -> SyntaxVisitorContinueKind {
    // We don't need to visit children because this code can't have imports.
    return .skipChildren
  }

  public override func visit(_ node: ClassDeclSyntax) -> SyntaxVisitorContinueKind {
    // We don't need to visit children because this code can't have imports.
    return .skipChildren
  }

  public override func visit(_ node: EnumDeclSyntax) -> SyntaxVisitorContinueKind {
    // We don't need to visit children because this code can't have imports.
    return .skipChildren
  }

  private func importStatement(from syntaxNode: ImportDeclSyntax) -> ImportStatement {
    let attribute = findAttribute(from: syntaxNode)
    let (main, submodule) = findModule(from: syntaxNode)
    let kind = findImportKind(from: syntaxNode)

    return ImportStatement(attribute: attribute, kind: kind, mainModule: main, submodule: submodule)
  }

  /// Finds the type of an import
  ///
  /// - Parameter syntaxNode: The Swift Syntax import declaration node
  ///
  /// - Returns: A string representing the kind of the import
  ///            e.g `import class UIKit.UIViewController` returns class
  ///            while `import UIKit` and `import UIKit.UIViewController` return an empty String
  private func findImportKind(from syntaxNode: ImportDeclSyntax) -> String {
    for token in syntaxNode.tokens {
      switch token.tokenKind {
      // List is from https://thoughtbot.com/blog/swift-imports
      case .typealiasKeyword,
           .structKeyword,
           .classKeyword,
           .enumKeyword,
           .protocolKeyword,
           .letKeyword,
           .varKeyword,
           .funcKeyword:
        return token.text
      default:
        break
      }
    }

    return ""
  }

  /// Finds the module and submodule of an import
  ///
  /// - Parameter syntaxNode: The Swift Syntax import declaration node
  ///
  /// - Returns: A String tuple representing the main module and submodule of the import.
  ///            e.g `import class UIKit.UIViewController` returns ("UIKit", "UIViewController")
  private func findModule(from syntaxNode: ImportDeclSyntax) -> (main: String, submodule: String) {
    var moduleIdentifier: String = ""
    var submoduleIdentifier: String = ""

    for child in syntaxNode.children {
      guard let accessPath = child.as(AccessPathSyntax.self) else {
        continue
      }

      for accessPathComponent in accessPath {
        // The main module name always comes before the submodule name, so we fullfill that first
        if moduleIdentifier.isEmpty {
          moduleIdentifier = accessPathComponent.name.text
          continue
        } else {
          submoduleIdentifier = accessPathComponent.name.text
          break
        }
      }
    }

    return (moduleIdentifier, submoduleIdentifier)
  }

  private func findAttribute(from syntaxNode: ImportDeclSyntax) -> String {
    for child in syntaxNode.children {
      guard let attributeList = child.as(AttributeListSyntax.self) else {
        continue
      }

      // This AttributeList is of the form ["@", "attribute"]
      // So we grab the last token
      return attributeList.lastToken?.text ?? ""
    }
    return ""
  }
}

public struct ImportStatement: Codable, Hashable {
  public var attribute: String = ""
  public var kind: String = ""
  public let mainModule: String
  public var submodule: String = ""
}
