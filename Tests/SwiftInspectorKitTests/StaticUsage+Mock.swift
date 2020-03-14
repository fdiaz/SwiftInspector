// Created by Francisco Diaz on 1/15/20.
// Copyright © 2020 Airbnb Inc. All rights reserved.

import Foundation
@testable import SwiftInspectorKit

extension StaticUsage {

  /// A convenience mock initializer to be used in tests
  /// This makes it easier to change the initializer of StaticUsage without refactoring tests
  static func mock(
    staticMember: StaticMember = .mock(),
    isUsed: Bool = true) -> StaticUsage
  {
    StaticUsage(staticMember: staticMember, isUsed: isUsed)
  }
}

extension StaticMember {

  /// A convenience mock initializer to be used in tests
  /// This makes it easier to change the initializer of StaticMember without refactoring tests
  static func mock(typeName: String = "Mock", memberName: String = "mockShared") -> StaticMember {
    StaticMember(typeName: typeName, memberName: memberName)
  }
}
