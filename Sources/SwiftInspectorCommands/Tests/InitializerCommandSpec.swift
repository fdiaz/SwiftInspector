// Created by Francisco Diaz on 3/27/20.
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

final class InitializerCommandSpec: QuickSpec {
  override func spec() {
    describe("run") {

      context("with no arguments") {
        it("fails") {
          let result = try? TestTask.run(withArguments: ["initializer"])
          expect(result?.didFail) == true
        }
      }

      context("when path is invalid") {
        it("fails when empty") {
          let result = try? TestTask.run(withArguments: ["initializer", "--path", "", "--name", "FakeName"])
          expect(result?.didFail) == true
        }

        it("fails when it doesn't exist") {
          let result = try? TestTask.run(withArguments: ["initializer", "--path", "/fake/path", "--name", "FakeName"])
          expect(result?.didFail) == true
        }
      }

      context("when name is passed and path exists") {
        var fileURL: URL!

        beforeEach {
          fileURL = try? Temporary.makeFile(content: """
          final class Some {
            init(some: String, someInt: Int) {}
          }
          """)
        }

        afterEach {
          try? Temporary.removeItem(at: fileURL)
        }

        it("fails when name is empty") {
          let result = try? TestTask.run(withArguments: ["initializer", "--path", fileURL.path, "--name", ""])
          expect(result?.didFail) == true
        }

        it("succeeds") {
          let result = try? TestTask.run(withArguments: ["initializer", "--path", fileURL.path, "--name", "Some"])
          expect(result?.didSucceed) == true
        }

        it("returns only the type names by default") {
          let result = try? TestTask.run(withArguments: ["initializer", "--path", fileURL.path, "--name", "Some"])
          expect(result?.outputMessage).to(contain("String Int"))
        }

        it("returns the name and type name if we disable type only") {
          let result = try? TestTask.run(withArguments: ["initializer", "--path", fileURL.path, "--name", "Some", "--disable-type-only"])
          expect(result?.outputMessage).to(contain("some,String someInt,Int"))
        }
      }

      context("when parameter-name is passed") {
        var fileURL: URL!

        beforeEach {
          fileURL = try? Temporary.makeFile(content: """
          final class Some {
            init(some: String, someInt: Int) {}
          }
          """)
        }

        it("filters out the initializers that don't have the parameter names") {
          let result = try? TestTask.run(withArguments: ["initializer", "--path", fileURL.path, "--name", "Some", "--parameter-name", "AnotherType"])
          expect(result?.outputMessage).toNot(contain("String"))
        }

        it("returns the initializers that have the same names") {
          let result = try? TestTask.run(withArguments: ["initializer", "--path", fileURL.path, "--name", "Some", "--parameter-name", "some", "someInt"])
          expect(result?.outputMessage).to(contain("String Int"))
        }

        it("returns the initializers that have the same names in different order") {
          let result = try? TestTask.run(withArguments: ["initializer", "--path", fileURL.path, "--name", "Some", "--parameter-name", "someInt", "some"])
          expect(result?.outputMessage).to(contain("String Int"))
        }
      }

    }
  }
}
