// Created by Tyler Hedrick on 8/17/20.
//
// Copyright (c) 2020 Tyler Hedrick
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

@testable import SwiftInspectorCore

final class PropertyAnalyzerCommandSpec: QuickSpec {
  override func spec() {
    describe("run") {

      context("with no arguments") {
        it("fails") {
          let result = try? TestTask.run(withArguments: ["properties"])
          expect(result?.didFail) == true
        }
      }

      context("when path is invalid") {
        it("fails when empty") {
          let result = try? TestTask.run(withArguments: ["properties", "--path", ""])
          expect(result?.didFail) == true
        }

        it("fails when not provided") {
          let result = try? TestTask.run(withArguments: ["properties", "--path"])
          expect(result?.didFail) == true
        }

        it("fails when it doesn't exist") {
          let result = try? TestTask.run(withArguments: ["properties", "--path", "/fake/path"])
          expect(result?.didFail) == true
        }

        it("fails when name is present but the file is invalid") {
          let result = try? TestTask.run(withArguments: ["properties", "--path", "/fake/path", "--name", "SomeType"])
          expect(result?.didFail) == true
        }
      }

      context("when name is passed") {
        var fileURL: URL!

        beforeEach {
          fileURL = try? Temporary.makeFile(content: """
          final class Some {
            public var thing: String = "Hello, World"
          }
          """)
        }

        afterEach {
          try? Temporary.removeItem(at: fileURL)
        }

        it("fails when name is empty") {
          let result = try? TestTask.run(withArguments: ["properties", "--path", fileURL.path, "--name", ""])
          expect(result?.didFail) == true
        }

        it("fails when name is not provided") {
          let result = try? TestTask.run(withArguments: ["properties", "--path", fileURL.path, "--name"])
          expect(result?.didFail) == true
        }

        it("fails when path is empty") {
          let result = try? TestTask.run(withArguments: ["properties", "--name", "Some"])
          expect(result?.didFail) == true
        }

        it("succeeds") {
          let result = try? TestTask.run(withArguments: ["properties", "--path", fileURL.path, "--name", "Some"])
          expect(result?.didSucceed) == true
        }

        it("returns the type name with property information including the name, access, and scope") {
          let result = try? TestTask.run(withArguments: ["properties", "--path", fileURL.path, "--name", "Some"])
          expect(result?.outputMessage).to(contain("Some,thing,public,instance"))
        }
      }
    }
  }
}
