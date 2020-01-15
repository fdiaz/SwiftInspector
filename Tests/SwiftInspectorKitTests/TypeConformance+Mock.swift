// Created by Francisco Diaz on 1/15/20.
// Copyright © 2020 Airbnb Inc. All rights reserved.

import Foundation
@testable import SwiftInspectorKit

extension TypeConformance {
  static func mock(
    typeName: String = "Mock",
    filePath: String = "/mock/Some.swift",
    doesConform: Bool = true) -> TypeConformance
  {
    TypeConformance(typeName: typeName, filePath: filePath, doesConform: doesConform)
  }

  var lastPathComponent: String? {
    let fileURL = URL(fileURLWithPath: filePath)
    return fileURL.lastPathComponent
  }
}
