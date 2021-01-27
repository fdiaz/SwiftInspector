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

final class InitializerAnalyzerSpec: QuickSpec {
  override func spec() {
    var fileURL: URL!
    var sut = InitializerAnalyzer(name: "FakeType")

    beforeEach {
      sut = InitializerAnalyzer(name: "FakeType")
    }

    afterEach {
      guard let fileURL = fileURL else {
        return
      }
      try? Temporary.removeItem(at: fileURL)
    }

    describe("analyze(fileURL:)") {
      context("when there is no initializer") {
        beforeEach {
          let content = """
                        public final class FakeType {}
                        """
          fileURL = try? Temporary.makeFile(content: content)
        }

        it("returns an empty array") {
          let result = try? sut.analyze(fileURL: fileURL)

          expect(result).to(beEmpty())
        }
      }

      context("when there is an initializer") {
        beforeEach {
          let content = """
          public final class FakeType {
            convenience init(someString: String, someInt: Int) {}
          }
          """
          fileURL = try? Temporary.makeFile(content: content)
        }

        it("detects the type name") {
          let result = try? sut.analyze(fileURL: fileURL)
          expect(result?.first?.typeName) == "FakeType"
        }

        it("returns an empty array if the type name is not present") {
          let sut = InitializerAnalyzer(name: "AnotherType")
          let result = try? sut.analyze(fileURL: fileURL)
          expect(result).to(beEmpty())
        }

        it("detects the parameters") {
          let result = try? sut.analyze(fileURL: fileURL)
          expect(result?.first?.parameters) == [
            InitializerStatement.Parameter(name: "someString", typeName: "String"),
            InitializerStatement.Parameter(name: "someInt", typeName: "Int"),
          ]
        }

        it("detects the modifier") {
          let result = try? sut.analyze(fileURL: fileURL)
          expect(result?.first?.modifiers) == .convenience
        }

        context("with default values") {
          beforeEach {
            let content = """
            public final class FakeType {
              convenience init(someString: String = "abc", someInt: Int = 2) {}
            }
            """
            fileURL = try? Temporary.makeFile(content: content)
          }

          it("detects the parameters") {
            let result = try? sut.analyze(fileURL: fileURL)
            expect(result?.first?.parameters) == [
              InitializerStatement.Parameter(name: "someString", typeName: "String"),
              InitializerStatement.Parameter(name: "someInt", typeName: "Int"),
            ]
          }

          it("detects the modifier") {
            let result = try? sut.analyze(fileURL: fileURL)
            expect(result?.first?.modifiers) == .convenience
          }
        }

        context("with a composition of types") {
          beforeEach {
            let content = """
            protocol Some {}
            protocol Another {}

            public final class FakeType {
              init(someString: Some & Another, someInt: Int) {}
            }
            """
            fileURL = try? Temporary.makeFile(content: content)
          }

          it("returns all the types in the array") {
            let result = try? sut.analyze(fileURL: fileURL)
            expect(result?.first?.parameters) == [
              InitializerStatement.Parameter(name: "someString", typeNames: ["Some", "Another"]),
              InitializerStatement.Parameter(name: "someInt", typeName: "Int"),
            ]
          }
        }

        context("with a tuple") {
          beforeEach {
            let content = """
            public final class FakeType {
              init(someTyple: (String, Int)) {}
            }
            """
            fileURL = try? Temporary.makeFile(content: content)
          }

          it("returns all the types in the array") {
            let result = try? sut.analyze(fileURL: fileURL)
            expect(result?.first?.parameters) == [
              InitializerStatement.Parameter(name: "someTyple", typeNames: ["String", "Int"]),
            ]
          }
        }

        context("with an argument label different than the parameter name") {
          beforeEach {
            let content = """
            public final class FakeType {
              init(someLabel someName: String) {}
            }
            """
            fileURL = try? Temporary.makeFile(content: content)
          }

          it("returns the correct parameter name") {
            let result = try? sut.analyze(fileURL: fileURL)
            expect(result?.first?.parameters) == [
              InitializerStatement.Parameter(name: "someName", typeNames: ["String"]),
            ]
          }
        }

        context("with an argument label of _") {
          beforeEach {
            let content = """
                   public final class FakeType {
                     init(_ someName: String) {}
                   }
                   """
            fileURL = try? Temporary.makeFile(content: content)
          }

          it("returns the correct parameter name") {
            let result = try? sut.analyze(fileURL: fileURL)
            expect(result?.first?.parameters) == [
              InitializerStatement.Parameter(name: "someName", typeNames: ["String"]),
            ]
          }
        }
      }

      context("with multiple initializers") {
        beforeEach {
          let content = """
          public struct AnotherType {
            init(fooBar: String)
          }

          public final class FakeType {
            init(someString: String) {}
            override init(someString: String, someInt: Int) {}
          }
          """
          fileURL = try? Temporary.makeFile(content: content)
        }

        it("returns the correct modifiers") {
          let result = try? sut.analyze(fileURL: fileURL)
          expect(result?.first?.modifiers) == .designated
          expect(result?.last?.modifiers) == [.override, .designated]
        }

        it("returns the correct parameters") {
          let result = try? sut.analyze(fileURL: fileURL)
          expect(result?.first?.parameters) == [
            InitializerStatement.Parameter(name: "someString", typeName: "String"),
          ]

          expect(result?.last?.parameters) == [
            InitializerStatement.Parameter(name: "someString", typeName: "String"),
            InitializerStatement.Parameter(name: "someInt", typeName: "Int"),
          ]
        }
      }

    }
  }
}
