// Created by Michael Bachand on 3/28/20.
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

@testable import SwiftInspectorCommands
@testable import SwiftInspectorCore

final class TypeLocationCommandSpec: QuickSpec {

  override func spec() {
    var pathURL: URL!

    describe("TypeLocationCommand") {
      afterEach {
        guard let pathURL = pathURL else {
          return
        }
        try? Temporary.removeItem(at: pathURL)
      }

      describe("run") {

        context("with no arguments") {
          it("fails") {
            let result = try? TestTypeLocationTask.run(path: nil, name: nil)
            expect(result?.didFail) == true
          }
        }

        context("path is valid") {
          beforeEach { pathURL = try? Temporary.makeFile(content: "struct Foo { }") }

          context("with no --name argument") {
            it("fails") {
              let result = try? TestTypeLocationTask.run(path: pathURL.path, name: nil)
              expect(result?.didFail) == true
            }
          }

          context("with an empty --name argument") {
            it("fails") {
              let result = try? TestTypeLocationTask.run(path: pathURL.path, name: "")
              expect(result?.didFail) == true
            }
          }
        }

        context("name is valid") {
          context("with no --path argument") {
            it("fails") {
              let result = try? TestTypeLocationTask.run(path: nil, name: "Foo")
              expect(result?.didFail) == true
            }
          }

          context("with an empty --path argument") {
            it("fails") {
              let result = try? TestTypeLocationTask.run(path: "", name: "Foo")
              expect(result?.didFail) == true
            }
          }
        }

        context("when path is a directory") {
          beforeEach { pathURL = try? Temporary.makeFolder() }

          it("fails") {
            let result = try? TestTypeLocationTask.run(path: pathURL.path, name: "Foo")
            expect(result?.didFail) == true
          }
        }

        context("when path is a file") {
          beforeEach { pathURL = try? Temporary.makeFile(content: "struct Foo { }") }

          it("succeeds") {
            let result = try? TestTypeLocationTask.run(path: pathURL.path, name: "Foo")
            expect(result?.didSucceed) == true
          }

          context("type is found") {
            it("outputs the correct line numbers") {
              let contents =
              """
              import Foundation

              struct Foo { }
              """

              pathURL = try? Temporary.makeFile(content: contents)

              let result = try? TestTypeLocationTask.run(path: pathURL.path, name: "Foo")
              expect(result?.outputMessage).to(contain("2 2"))
            }
          }

          context("type is not found") {
            it("outputs nothing") {
              let contents =
              """
              import Foundation

              struct Foo { }
              """

              pathURL = try? Temporary.makeFile(content: contents)

              let result = try? TestTypeLocationTask.run(path: pathURL.path, name: "Bar")
              expect(result?.outputMessage).to(equal("\n"))
            }
          }

          context("multiple types found") {
            it("outputs line numbers for each type") {
              let contents =
              """
              import Foundation

              struct Foo { }

              public final class Bar {
                enum Foo { }
              }
              """

              pathURL = try? Temporary.makeFile(content: contents)

              let result = try? TestTypeLocationTask.run(path: pathURL.path, name: "Foo")
              let lines = result?.outputMessage?.split { $0.isNewline }
              expect(lines?.count) == 2
              expect(lines?.first).to(equal("2 2"))
              expect(lines?.last).to(equal("5 5"))
            }
          }
        }
      }
    }

    describe("LocatedType") {

      describe("outputString") {

        it("shows index of start and end line") {
          let locatedType = LocatedType(
            name: "MyType",
            indexOfStartingLine: 10,
            indexOfEndingLine: 12)
          expect(locatedType.outputString()) == "10 12"
        }
      }
    }
  }
}

private struct TestTypeLocationTask {
  /// - Parameters:
  ///   - path: The path with which to execute the task. The `--path` argument is not passed to the task if `nil`.
  ///   - name: The name with which to execute the task. The `--name` argument is not passed to task if `nil`.
  fileprivate static func run(path: String?, name: String?) throws -> TaskStatus {
    var arguments = ["type-location"]
    name.map { arguments += ["--name", $0] }
    path.map { arguments += ["--path", $0] }
    return try TestTask.run(withArguments: arguments)
  }
}
