// Created by Francisco Diaz on 10/13/19.
//
// Copyright (c) 2020 Francisco Diaz
//
// Distributed under the MIT License
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

import Foundation

struct TestTask {

  /// Finds the Swift Inspector executable in Derived Data and passes an array of arguments to it.
  /// This method should only be used for testing.
  /// - Parameter arguments: A set of arguments to pass to the Swift Inspector executable
  static func run(withArguments arguments: [String]) throws -> TaskStatus {
    let process = Process()
    process.executableURL = productsDirectory.appendingPathComponent("swiftinspector")
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

    return TaskStatus(exitStatus: process.terminationStatus, stdOutputString: outputString, stdErrorString: errorString)
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

enum TaskStatus: Equatable {
  init(exitStatus: Int32, stdOutputString: String?, stdErrorString: String?) {
    if exitStatus == 0 {
      self = .success(message: stdOutputString)
    } else {
      self = .failure(message: stdErrorString, exitStatus: exitStatus)
    }
  }

  case success(message: String?)
  case failure(message: String?, exitStatus: Int32)

  var didSucceed: Bool {
    switch self {
    case .success(_): return true
    case .failure(_, _): return false
    }
  }

  var didFail: Bool { return !didSucceed }

  var outputMessage: String? {
    switch self {
    case .success(let message): return message
    case .failure(_, _): return nil
    }
  }

  var errorMessage: String? {
    switch self {
    case .success(_): return nil
    case .failure(let message, _): return message
    }
  }
}
