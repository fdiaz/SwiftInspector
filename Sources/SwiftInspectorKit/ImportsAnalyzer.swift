// Created by Francisco Diaz on 10/14/19.
// Copyright © 2019 Airbnb Inc. All rights reserved.

import Foundation
import SwiftSyntax

public final class ImportsAnalyzer: Analyzer {

  /// - Parameter cachedSyntaxTree: The cached syntax tree to return the AST tree from
  public init(cachedSyntaxTree: CachedSyntaxTree = .init()) {
    self.cachedSyntaxTree = cachedSyntaxTree
  }

  /// Analyzes if the Swift file contains conformances to the typeName provided
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
    let (main, submodule) = findModule(from: syntaxNode)
    let kind = findImportKind(from: syntaxNode)

    return ImportStatement(kind: kind, mainModule: main, submodule: submodule)
  }

  /// Finds the type of an import
  /// e.g `import class UIKit.UIViewController` returns class
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
  /// e.g `import class UIKit.UIViewController` returns ("UIKit", "UIViewController")
  private func findModule(from syntaxNode: ImportDeclSyntax) -> (String, String) {
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

public struct ImportStatement: StandardOutputConvertible {
  public var standardOutput: String { mainModule }

  public var kind: String = ""
  public let mainModule: String
  public var submodule: String = ""
}
