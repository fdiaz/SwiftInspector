// Created by Francisco Diaz on 10/14/19.
// Copyright © 2019 Airbnb Inc. All rights reserved.

import Foundation
import SwiftSyntax

public final class TypeConformanceAnalyzer {

  /// - Parameter typeName: The name of the type we're looking a type to conform to
  /// - Parameter fileURL: The fileURL where the Swift file is located
  public init(typeName: String, fileURL: URL) {
    self.typeName = typeName
    self.fileURL = fileURL
  }

  /// Analyzes if the Swift file contains conformances to the typeName provided
  public func analyze() throws -> TypeConformance {
    let sourceFile: SourceFileSyntax = try SyntaxTreeParser.parse(fileURL)
    return try analyze(syntax: sourceFile)
  }

  private func analyze(syntax: SourceFileSyntax) throws -> TypeConformance {
    var doesConform = false
    let reader = TypeConformanceSyntaxReader()
    reader.onConformance = { node in
      doesConform = doesConform || self.isSyntaxNode(node, ofType: self.typeName)
    }
    let _ = reader.visit(syntax)

    return TypeConformance(typeName: typeName, fileName: fileURL.lastPathComponent, doesConform: doesConform)
  }

  private func isSyntaxNode(_ node: InheritedTypeSyntax, ofType typeName: String) -> Bool {
    // Remove leading and trailing whitespace trivia
    let syntaxTypeName = String(describing: node.typeName).trimmingCharacters(in: .whitespaces)
    return (syntaxTypeName == self.typeName)
  }

  private let typeName: String
  private let fileURL: URL
}

public struct TypeConformance {
  let typeName: String
  let fileName: String
  let doesConform: Bool
}

private class TypeConformanceSyntaxReader: SyntaxRewriter {
  var onConformance: (InheritedTypeSyntax) -> Void = { _ in }

  override func visit(_ node: InheritedTypeSyntax) -> Syntax {
    onConformance(node)
    return super.visit(node)
  }
}
