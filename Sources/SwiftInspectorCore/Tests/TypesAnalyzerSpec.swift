// Created by Tyler Hedrick 8/13/20.
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

@testable import SwiftInspectorCore

final class TypesAnalyzerSpec: QuickSpec {

  override func spec() {
    var fileURL: URL!
    var sut: TypesAnalyzer!

    beforeEach {
      sut = TypesAnalyzer()
    }

    afterEach {
      guard let fileURL = fileURL else {
        return
      }
      try? Temporary.removeItem(at: fileURL)
    }

    describe("analyze(fileURL:)") {
      context("there are no types present") {
        beforeEach {
          let content =
          """
          import Foundation
          """
          fileURL = try? Temporary.makeFile(content: content)
        }

        it("returns empty array") {
          let result = try? sut.analyze(fileURL: fileURL)
          expect(result).to(beEmpty())
        }
      }

      context("struct is present") {
        beforeEach {
          let content =
          """
          struct Foo { }
          """
          fileURL = try? Temporary.makeFile(content: content)
        }

        it("returns the type information for the struct") {
          let result = try? sut.analyze(fileURL: fileURL)
          expect(result).notTo(beEmpty())
          expect(result!.first!.name) == "Foo"
          expect(result!.first!.type) == .struct
        }
      }

      context("enum is present") {
        beforeEach {
          let content =
          """
          enum Foo { }
          """
          fileURL = try? Temporary.makeFile(content: content)
        }

        it("returns the type information for the enum") {
          let result = try? sut.analyze(fileURL: fileURL)
          expect(result).notTo(beEmpty())
          expect(result!.first!.name) == "Foo"
          expect(result!.first!.type) == .enum
        }
      }

      context("class is present") {
        beforeEach {
          let content =
          """
          class Foo { }
          """
          fileURL = try? Temporary.makeFile(content: content)
        }

        it("returns the type information for the class") {
          let result = try? sut.analyze(fileURL: fileURL)
          expect(result).notTo(beEmpty())
          expect(result!.first!.name) == "Foo"
          expect(result!.first!.type) == .class
        }
      }

      context("protocol is present") {
        beforeEach {
          let content =
          """
          protocol Foo { }
          """
          fileURL = try? Temporary.makeFile(content: content)
        }

        it("returns the type information for the protocol") {
          let result = try? sut.analyze(fileURL: fileURL)
          expect(result).notTo(beEmpty())
          expect(result!.first!.name) == "Foo"
          expect(result!.first!.type) == .protocol
        }
      }

      context("struct is present with comment") {
        beforeEach {
          let content =
          """
          // This is a comment
          struct Foo { }
          """
          fileURL = try? Temporary.makeFile(content: content)
        }

        it("returns the type information for the struct including the comment") {
          let result = try? sut.analyze(fileURL: fileURL)
          expect(result).notTo(beEmpty())
          expect(result!.first!.name) == "Foo"
          expect(result!.first!.type) == .struct
          expect(result!.first!.comment) == "// This is a comment"
        }
      }

      context("enum is present with comment") {
        beforeEach {
          let content =
          """
          // This is a comment
          enum Foo { }
          """
          fileURL = try? Temporary.makeFile(content: content)
        }

        it("returns the type information for the enum including the comment") {
          let result = try? sut.analyze(fileURL: fileURL)
          expect(result).notTo(beEmpty())
          expect(result!.first!.name) == "Foo"
          expect(result!.first!.type) == .enum
          expect(result!.first!.comment) == "// This is a comment"
        }
      }

      context("class is present with comment") {
        beforeEach {
          let content =
          """
          // This is a comment
          class Foo { }
          """
          fileURL = try? Temporary.makeFile(content: content)
        }

        it("returns the type information for the class including the comment") {
          let result = try? sut.analyze(fileURL: fileURL)
          expect(result).notTo(beEmpty())
          expect(result!.first!.name) == "Foo"
          expect(result!.first!.type) == .class
          expect(result!.first!.comment) == "// This is a comment"
        }
      }

      context("protocol is present with comment") {
        beforeEach {
          let content =
          """
          // This is a comment
          protocol Foo { }
          """
          fileURL = try? Temporary.makeFile(content: content)
        }

        it("returns the type information for the protocol including the comment") {
          let result = try? sut.analyze(fileURL: fileURL)
          expect(result).notTo(beEmpty())
          expect(result!.first!.name) == "Foo"
          expect(result!.first!.type) == .protocol
          expect(result!.first!.comment) == "// This is a comment"
        }
      }

      context("multiple types present") {
        beforeEach {
          let content =
          """
          // This is a comment
          protocol Foo { }

          // This is a different comment
          private final class Bar: Foo { }
          """
          fileURL = try? Temporary.makeFile(content: content)
        }

        it("returns the type information for both types including the comments") {
          let result = try? sut.analyze(fileURL: fileURL)
          expect(result).notTo(beEmpty())
          expect(result!.first!.name) == "Foo"
          expect(result!.first!.type) == .protocol
          expect(result!.first!.comment) == "// This is a comment"

          expect(result![1].name) == "Bar"
          expect(result![1].type) == .class
          expect(result![1].comment) == "// This is a different comment"
        }
      }


    }
  }
}
