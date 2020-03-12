// Created by Francisco Diaz on 3/11/20.
// Copyright © 2020 Airbnb Inc. All rights reserved.

import ArgumentParser

enum InspectorError {
  static func emptyArgument(argumentName: String) -> ValidationError {
    ValidationError("Please provide a \(argumentName) value")
  }

  static func invalidArgument(argumentName: String, value: String) -> ValidationError {
    ValidationError("The provided \(argumentName) value \(value) is invalid")
  }
}
