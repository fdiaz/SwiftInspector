// Created by Francisco Diaz on 3/25/20.
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
import Nimble
import Quick
import SwiftInspectorTestHelpers

@testable import SwiftInspectorAnalyzers

final class TypealiasCommandSpec: QuickSpec {
  override func spec() {
    var fileURL: URL!
    var path: String!

    beforeEach {
      fileURL = try? Temporary.makeFile(content: "typealias SomeAlias = SomeType")
      path = fileURL?.path ?? ""
    }

    afterEach {
      try? Temporary.removeItem(at: fileURL)
    }

    describe("run") {
      context("with no arguments") {
        it("fails") {
          let result = try? TestTask.run(withArguments: ["typealias"])
          expect(result?.didFail) == true
        }
      }

      context("with no --name argument") {
        var result: TaskStatus?
        beforeEach {
          result = try? TestTask.run(withArguments: ["typealias", "--path", path])
        }

        it("succeeds") {
          expect(result?.didSucceed) == true
        }

        it("outputs the typealias information") {
          expect(result?.outputMessage).to(contain("SomeAlias"))
        }

        it("does not output the typelias identifiers") {
          expect(result?.outputMessage).toNot(contain("SomeType"))
        }

        context("when a typealias is defined multiple times") {
          it("only returns one the typealias name once") {
            fileURL = try? Temporary.makeFile(content: """
                                                       typealias SomeAlias = SomeType
                                                       typealias SomeAlias = SomethingElse
                                                       """
            )
            result = try? TestTask.run(withArguments: ["typealias", "--path", fileURL!.path])

            let lines = result?.outputMessage?.split { $0.isNewline }.count
            expect(lines) == 1
          }
        }
      }

      context("with an empty --name argument") {
        it("succeeds") {
          let result = try? TestTask.run(withArguments: ["typealias", "--name", "", "--path", path])
          expect(result?.didSucceed) == true
        }
      }

      context("with an empty --path argument") {
        it("fails") {
          let result = try? TestTask.run(withArguments: ["typealias", "--path", ""])
          expect(result?.didFail) == true
        }
      }

      context("with --name and --path") {

        context("when path doesn't exist") {
          it("fails") {
            let result = try? TestTask.run(withArguments: ["typealias", "--name", "SomeAlias", "--path", "/abc"])
            expect(result?.didFail) == true
          }
        }

        context("when path exists") {
          it("succeeds") {
            let result = try? TestTask.run(withArguments: ["typealias", "--name", "SomeAlias", "--path", path])
            expect(result?.didSucceed) == true
          }
        }

        it("outputs the typealias information") {
          let result = try? TestTask.run(withArguments: ["typealias", "--name", "SomeAlias", "--path", path])
          expect(result?.outputMessage).to(contain("SomeAlias"))
        }

        it("does not output the typealias information if the name is different") {
          let result = try? TestTask.run(withArguments: ["typealias", "--name", "AnotherTypealias", "--path", path])
          expect(result?.outputMessage).toNot(contain("SomeAlias"))
        }

        it("outputs the typealias identifiers") {
          let result = try? TestTask.run(withArguments: ["typealias", "--name", "SomeAlias", "--path", path])
          expect(result?.outputMessage).to(contain("SomeAlias"))
          expect(result?.outputMessage).to(contain("SomeType"))
        }

        context("with a file that has two typealias with the same name and identifiers") {
          it("returns the typealias information once") {
            let fileURL = try! Temporary.makeFile(
              content: """
                       typealias Foo = Bar

                       struct MyNamespace {

                         typealias Foo = Bar

                       }
                       """
            )
            let result = try? TestTask.run(withArguments: ["typealias", "--name", "Foo", "--path", fileURL.path])

            let lines = result?.outputMessage?.split { $0.isNewline }

            expect(lines?.count) == 1
          }
        }

        context("with a file that has two typealias with the same name and different identifiers") {
          it("returns the typealias information twice") {
            let fileURL = try! Temporary.makeFile(
              content: """
                       typealias Foo = Bar1

                       struct MyNamespace {

                         typealias Foo = Bar2

                       }
                       """
            )
            let result = try? TestTask.run(withArguments: ["typealias", "--name", "Foo", "--path", fileURL.path])

            let lines = result?.outputMessage?.split { $0.isNewline }

            expect(lines?.count) == 2
          }
        }
      }

    }
  }
}
