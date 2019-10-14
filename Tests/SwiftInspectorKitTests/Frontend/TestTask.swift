// Created by Francisco Diaz on 10/13/19.
// Copyright © 2019 Airbnb Inc. All rights reserved.

import Foundation

struct TestTask {

  /// Finds the Swift Inspector executable in Derived Data and passes an array of arguments to it.
  /// This method should only be used for testing.
  /// - Parameter arguments: A set of arguments to pass to the Swift Inspector executable
  static func run(withArguments arguments: [String]) throws -> TaskStatus {
    let process = Process()
    process.executableURL = productsDirectory.appendingPathComponent("SwiftInspector")
    process.arguments = arguments

    let standardOutputPipe = Pipe()
    process.standardOutput = standardOutputPipe

    let standardErrorPipe = Pipe()
    process.standardError = standardErrorPipe

    try process.run()
    process.waitUntilExit()

    let outputData = standardOutputPipe.fileHandleForReading.readDataToEndOfFile()
    let outputString = String(decoding: outputData, as: UTF8.self)

    let errorData = standardErrorPipe.fileHandleForReading.readDataToEndOfFile()
    let errorString = String(decoding: errorData, as: UTF8.self)

    return TaskStatus(status: process.terminationStatus, stdOutputString: outputString, stdErrorString: errorString)
  }

  // Locates the Products directory in Derived Data where the executable should be
  private static var productsDirectory: URL {
    #if os(macOS)
    for bundle in Bundle.allBundles where bundle.bundlePath.hasSuffix(".xctest") {
      return bundle.bundleURL.deletingLastPathComponent()
    }
    fatalError("Couldn't find the products directory")
    #else
    return Bundle.main.bundleURL
    #endif
  }
}

struct TaskStatus {
  let status: Int32
  let stdOutputString: String?
  let stdErrorString: String?

  var didSucceed: Bool { return status == 0 }
  var didFail: Bool { return !didSucceed }
}
