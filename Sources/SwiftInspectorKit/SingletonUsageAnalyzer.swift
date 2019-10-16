// Created by Francisco Diaz on 10/16/19.
// Copyright © 2019 Airbnb Inc. All rights reserved.

import Foundation
import SwiftSyntax

public final class SingletonUsageAnalyzer {

  /// - Parameter singleton: The type and property names of the singleton we're looking
  public init(singleton: Singleton) {
    self.singleton = singleton
  }

  /// Analyzes if the Swift file contains the singleton specified
  /// - Parameter fileURL: The fileURL where the Swift file is located
  public func analyze(fileURL: URL) throws -> SingletonUsage {
    var doesContain = false
    let syntax: SourceFileSyntax = try SyntaxParser.parse(fileURL)
    let reader = SingletonUsageReader() { node in
      print(node)
    }
    let _ = reader.visit(syntax)

    return SingletonUsage(singleton: self.singleton, fileName: fileURL.lastPathComponent, doesContain: doesContain)
  }

  // MARK: Private
  private let singleton: Singleton
}

public struct Singleton: Equatable {
  let typeName: String
  let propertyName: String
}

public struct SingletonUsage: Equatable {
  let singleton: Singleton
  let fileName: String
  let doesContain: Bool
}

// TODO: Update to use SyntaxVisitor when this bug is resolved (https://bugs.swift.org/browse/SR-11591)
private final class SingletonUsageReader: SyntaxRewriter {
  init(onNodeVisit: @escaping (MemberAccessExprSyntax) -> Void) {
    self.onNodeVisit = onNodeVisit
  }

  override func visit(_ node: MemberAccessExprSyntax) -> ExprSyntax {
    onNodeVisit(node)
    return super.visit(node)
  }

  private let onNodeVisit: (MemberAccessExprSyntax) -> Void
}
