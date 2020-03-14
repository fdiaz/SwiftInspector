// Created by Francisco Diaz on 1/15/20.
// Copyright © 2020 Airbnb Inc. All rights reserved.

import Foundation
@testable import SwiftInspectorKit

extension TypeConformance {

  /// A convenience mock initializer to be used in tests
  /// This makes it easier to change the initializer of TypeConformance without refactoring tests
  static func mock(
    typeName: String = "Mock",
    doesConform: Bool = true) -> TypeConformance
  {
    TypeConformance(typeName: typeName, doesConform: doesConform)
  }
}
