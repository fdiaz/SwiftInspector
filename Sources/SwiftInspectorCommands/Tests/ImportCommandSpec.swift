// Created by Francisco Diaz on 3/11/20.
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

import Nimble
import Quick
import Foundation

@testable import SwiftInspectorAnalyzers

final class ImportCommandSpec: QuickSpec {
  override func spec() {
    describe("run") {

      context("with no arguments") {
        it("fails") {
          let result = try? TestTask.run(withArguments: ["imports"])
          expect(result?.didFail) == true
        }
      }

      context("with an empty --path argument") {
        it("fails") {
          let result = try? TestStaticUsageTask.run(path: "")
          expect(result?.didFail) == true
        }
      }

      context("when path doesn't exist") {
        it("fails") {
          let result = try? TestStaticUsageTask.run(path: "/abc")
          expect(result?.didFail) == true
        }
      }

      context("when path exists") {
        var fileURL: URL!

        beforeEach {
          fileURL = try? Temporary.makeFile(content: "@testable import struct Foundation.Some")
        }

        afterEach {
          try? Temporary.removeItem(at: fileURL)
        }

        it("succeeds") {
          let result = try? TestStaticUsageTask.run(path: fileURL.path)
          expect(result?.didSucceed) == true
        }

        it("outputs only the main module by default") {
          let result = try? TestStaticUsageTask.run(path: fileURL.path)
          expect(result?.outputMessage) == "Foundation\n"
        }

        it("outputs the full import if full is passed") {
          let result = try? TestStaticUsageTask.run(path: fileURL.path, arguments: ["--mode", "full"])
          expect(result?.outputMessage).to(contain("@testable struct Foundation.Some"))
        }
      }

      context("when path is a folder") {
        var folderURL: URL!
        beforeEach {
          folderURL = try! Temporary.makeFolder()
        }
        afterEach {
          try! Temporary.removeItem(at: folderURL)
        }

        it("succeeds") {
          let result = try? TestStaticUsageTask.run(path: folderURL.path)

          expect(result?.didSucceed) == true
        }

        it("outputs the correct modules") {
          let _ = try? Temporary.makeFile(
            content: """
                     import Foundation
                     import UIKit
                     import MyService
                     """,
            atPath: folderURL.path)

          let result = try? TestStaticUsageTask.run(path: folderURL.path)
          let outputMessageLines = result?.outputMessage?.split { $0.isNewline }
          expect(outputMessageLines).to(contain(["Foundation", "UIKit", "MyService"]))
        }
      }

    }

  }
}

private struct TestStaticUsageTask {
  fileprivate static func run(path: String, arguments: [String] = []) throws -> TaskStatus {
    let arguments = ["imports", "--path", path] + arguments
    return try TestTask.run(withArguments: arguments)
  }
}
