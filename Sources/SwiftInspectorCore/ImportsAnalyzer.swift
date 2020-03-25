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

public final class ImportsAnalyzer: Analyzer {

  /// - Parameter cachedSyntaxTree: The cached syntax tree to return the AST tree from
  public init(cachedSyntaxTree: CachedSyntaxTree = .init()) {
    self.cachedSyntaxTree = cachedSyntaxTree
  }

  /// Analyzes the imports of the Swift file
  /// - Parameter fileURL: The fileURL where the Swift file is located
  public func analyze(fileURL: URL) throws -> [ImportStatement] {
    let syntax: SourceFileSyntax = try cachedSyntaxTree.syntaxTree(for: fileURL)
    var statements: [ImportStatement] = []
    let reader = ImportSyntaxReader() { [unowned self] node in
      let statement = self.importStatement(from: node)
      statements.append(statement)
    }
    _ = reader.visit(syntax)

    return statements
  }

  // MARK: Private

  private let cachedSyntaxTree: CachedSyntaxTree

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
      guard let accessPath = child as? AccessPathSyntax else {
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
      guard let attributeList = child as? AttributeListSyntax else {
        continue
      }

      // This AttributeList is of the form ["@", "attribute"]
      // So we grab the last token
      return attributeList.lastToken?.text ?? ""
    }
    return ""
  }
}

// TODO: Update to use SyntaxVisitor when this bug is resolved (https://bugs.swift.org/browse/SR-11591)
private final class ImportSyntaxReader: SyntaxRewriter {
  init(onNodeVisit: @escaping (ImportDeclSyntax) -> Void) {
    self.onNodeVisit = onNodeVisit
  }

  override func visit(_ node: ImportDeclSyntax) -> DeclSyntax {
    onNodeVisit(node)
    return super.visit(node)
  }

  let onNodeVisit: (ImportDeclSyntax) -> Void
}

public struct ImportStatement: Hashable {
  public var attribute: String = ""
  public var kind: String = ""
  public let mainModule: String
  public var submodule: String = ""
}
