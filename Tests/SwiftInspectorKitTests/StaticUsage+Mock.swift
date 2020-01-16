// Created by Francisco Diaz on 1/15/20.
// Copyright © 2020 Airbnb Inc. All rights reserved.

import Foundation
@testable import SwiftInspectorKit

extension StaticUsage {

  /// A convenience mock initializer to be used in tests
  /// This makes it easier to change the initializer of StaticUsage without refactoring tests
  static func mock(
    staticMember: StaticMember = .mock(),
    filePath: String = "mock/Some.swift",
    isUsed: Bool = true) -> StaticUsage
  {
    StaticUsage(staticMember: staticMember, filePath: filePath, isUsed: isUsed)
  }

  /// The last path component of the provided filePath property
  var lastPathComponent: String? {
    let fileURL = URL(fileURLWithPath: filePath)
    return fileURL.lastPathComponent
  }
}

extension StaticMember {

  /// A convenience mock initializer to be used in tests
  /// This makes it easier to change the initializer of StaticMember without refactoring tests
  static func mock(typeName: String = "Mock", memberName: String = "mockShared") -> StaticMember {
    StaticMember(typeName: typeName, memberName: memberName)
  }
}
