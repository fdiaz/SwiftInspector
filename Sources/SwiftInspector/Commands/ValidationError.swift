// Created by Francisco Diaz on 3/11/20.
// Copyright © 2020 Airbnb Inc. All rights reserved.

enum ValidationError: Error {
  case emptyArgument(argumentName: String)
  case invalidArgument(argumentName: String, value: String)

  var localizedDescription: String {
    switch self {
    case .emptyArgument(let argumentName):
      return "Please provide a \(argumentName) argument"
    case .invalidArgument(let argumentName, let value):
      return "The provided \(argumentName) value \(value) is invalid"
    }
  }
}
