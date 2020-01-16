// Created by Francisco Diaz on 1/15/20.
// Copyright © 2020 Airbnb Inc. All rights reserved.

import Foundation
@testable import SwiftInspectorKit

extension TypeConformance {

  /// A convenience mock initializer to be used in tests
  /// This makes it easier to change the initializer of TypeConformance without refactoring tests
  static func mock(
    typeName: String = "Mock",
    filePath: String = "/mock/Some.swift",
    doesConform: Bool = true) -> TypeConformance
  {
    TypeConformance(typeName: typeName, filePath: filePath, doesConform: doesConform)
  }

  /// The last path component of the provided provided filePath property
  var lastPathComponent: String? {
    let fileURL = URL(fileURLWithPath: filePath)
    return fileURL.lastPathComponent
  }
}
