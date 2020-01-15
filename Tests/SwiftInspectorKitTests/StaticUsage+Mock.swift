// Created by Francisco Diaz on 1/15/20.
// Copyright © 2020 Airbnb Inc. All rights reserved.

import Foundation
@testable import SwiftInspectorKit

extension StaticUsage {
  static func mock(
    staticMember: StaticMember = .mock(),
    filePath: String = "mock/Some.swift",
    isUsed: Bool = true) -> StaticUsage
  {
    StaticUsage(staticMember: staticMember, filePath: filePath, isUsed: isUsed)
  }

  var lastPathComponent: String? {
    let fileURL = URL(fileURLWithPath: filePath)
    return fileURL.lastPathComponent
  }
}

extension StaticMember {
  static func mock(typeName: String = "Mock", memberName: String = "mockShared") -> StaticMember {
    StaticMember(typeName: typeName, memberName: memberName)
  }
}
