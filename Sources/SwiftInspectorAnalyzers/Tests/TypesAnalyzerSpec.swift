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

@testable import SwiftInspectorAnalyzers

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
        var result: [TypeInfo]?

        beforeEach {
          let content =
          """
          struct Foo { }
          """
          fileURL = try? Temporary.makeFile(content: content)
          result = try? sut.analyze(fileURL: fileURL)
        }

        it("has a non-empty result") {
          expect(result).notTo(beEmpty())
        }
        it("returns the type's name") {
          expect(result?[0].name) == "Foo"
        }
        it("returns the type's Type") {
          expect(result?[0].type) == .struct
        }
        it("has empty comments") {
          expect(result?[0].comment.isEmpty) == true
        }
      }

      context("enum is present") {
        var result: [TypeInfo]?

        beforeEach {
          let content =
          """
          enum Foo { }
          """
          fileURL = try? Temporary.makeFile(content: content)
          result = try? sut.analyze(fileURL: fileURL)
        }

        it("has a non-empty result") {
          expect(result).notTo(beEmpty())
        }
        it("returns the type's name") {
          expect(result?[0].name) == "Foo"
        }
        it("returns the type's Type") {
          expect(result?[0].type) == .enum
        }
        it("has empty comments") {
          expect(result?[0].comment.isEmpty) == true
        }
      }

      context("class is present") {
        var result: [TypeInfo]?

        beforeEach {
          let content =
          """
          class Foo { }
          """
          fileURL = try? Temporary.makeFile(content: content)
          result = try? sut.analyze(fileURL: fileURL)
        }

        it("has a non-empty result") {
          expect(result).notTo(beEmpty())
        }
        it("returns the type's name") {
          expect(result?[0].name) == "Foo"
        }
        it("returns the type's Type") {
          expect(result?[0].type) == .class
        }
        it("has empty comments") {
          expect(result?[0].comment.isEmpty) == true
        }
      }

      context("protocol is present") {
        var result: [TypeInfo]?

        beforeEach {
          let content =
          """
          protocol Foo { }
          """
          fileURL = try? Temporary.makeFile(content: content)
          result = try? sut.analyze(fileURL: fileURL)
        }

        it("has a non-empty result") {
          expect(result).notTo(beEmpty())
        }
        it("returns the type's name") {
          expect(result?[0].name) == "Foo"
        }
        it("returns the type's Type") {
          expect(result?[0].type) == .protocol
        }
        it("has empty comments") {
          expect(result?[0].comment.isEmpty) == true
        }
      }

      context("struct is present with comment") {
        var result: [TypeInfo]?

        beforeEach {
          let content =
          """
          // This is a comment
          struct Foo { }
          """
          fileURL = try? Temporary.makeFile(content: content)
          result = try? sut.analyze(fileURL: fileURL)
        }

        it("has a non-empty result") {
          expect(result).notTo(beEmpty())
        }
        it("returns the type's name") {
          expect(result?[0].name) == "Foo"
        }
        it("returns the type's Type") {
          expect(result?[0].type) == .struct
        }
        it("returns comments associated with the type") {
          expect(result?[0].comment).to(contain("// This is a comment"))
        }
      }

      context("enum is present with comment") {
        var result: [TypeInfo]?

        beforeEach {
          let content =
          """
          // This is a comment
          enum Foo { }
          """
          fileURL = try? Temporary.makeFile(content: content)
          result = try? sut.analyze(fileURL: fileURL)
        }

        it("has a non-empty result") {
          expect(result).notTo(beEmpty())
        }
        it("returns the type's name") {
          expect(result?[0].name) == "Foo"
        }
        it("returns the type's Type") {
          expect(result?[0].type) == .enum
        }
        it("returns comments associated with the type") {
          expect(result?[0].comment).to(contain("// This is a comment"))
        }
      }

      context("class is present with comment") {
        var result: [TypeInfo]?

        beforeEach {
          let content =
          """
          // This is a comment
          class Foo { }
          """
          fileURL = try? Temporary.makeFile(content: content)
          result = try? sut.analyze(fileURL: fileURL)
        }

        it("has a non-empty result") {
          expect(result).notTo(beEmpty())
        }
        it("returns the type's name") {
          expect(result?[0].name) == "Foo"
        }
        it("returns the type's Type") {
          expect(result?[0].type) == .class
        }
        it("returns comments associated with the type") {
          expect(result?[0].comment).to(contain("// This is a comment"))
        }
      }

      context("protocol is present with comment") {
        var result: [TypeInfo]?

        beforeEach {
          let content =
          """
          // This is a comment
          protocol Foo { }
          """
          fileURL = try? Temporary.makeFile(content: content)
          result = try? sut.analyze(fileURL: fileURL)
        }

        it("has a non-empty result") {
          expect(result).notTo(beEmpty())
        }
        it("returns the type's name") {
          expect(result?[0].name) == "Foo"
        }
        it("returns the type's Type") {
          expect(result?[0].type) == .protocol
        }
        it("returns comments associated with the type") {
          expect(result?[0].comment).to(contain("// This is a comment"))
        }
      }

      context("multiple types present") {
        var result: [TypeInfo]?

        beforeEach {
          let content =
          """
          // This is a comment
          protocol Foo { }

          // This is a different comment
          private final class Bar: Foo { }
          """
          fileURL = try? Temporary.makeFile(content: content)
          result = try? sut.analyze(fileURL: fileURL)
        }

        it("has a non-empty result") {
          expect(result).notTo(beEmpty())
        }
        it("returns the first type's name") {
          expect(result?[0].name) == "Foo"
        }
        it("returns the first type's Type") {
          expect(result?[0].type) == .protocol
        }
        it("returns the comments associated with the first type") {
          expect(result?[0].comment).to(contain("// This is a comment"))
        }

        it("returns the second type's name") {
          expect(result?[1].name) == "Bar"
        }
        it("returns the second type's Type") {
          expect(result?[1].type) == .class
        }
        it("returns the comments associated with the second type") {
          expect(result?[1].comment).to(contain("// This is a different comment"))
        }
      }

      context("line comments") {
        var result: [TypeInfo]?

        beforeEach {
          let content =
          """
          // This is a comment
          protocol Foo { }
          """
          fileURL = try? Temporary.makeFile(content: content)
          result = try? sut.analyze(fileURL: fileURL)
        }

        it("contains the comment") {
          expect(result?[0].comment).to(contain("// This is a comment"))
        }
      }

      context("block comments") {
        var result: [TypeInfo]?

        beforeEach {
          let content =
          """
          /* This is a comment */
          protocol Foo { }
          """
          fileURL = try? Temporary.makeFile(content: content)
          result = try? sut.analyze(fileURL: fileURL)
        }

        it("contains the comment") {
          expect(result?[0].comment).to(contain("/* This is a comment */"))
        }
      }

      context("doc line comments") {
        var result: [TypeInfo]?

        beforeEach {
          let content =
          """
          /// This is a comment
          protocol Foo { }
          """
          fileURL = try? Temporary.makeFile(content: content)
          result = try? sut.analyze(fileURL: fileURL)
        }

        it("contains the comment") {
          expect(result?[0].comment).to(contain("/// This is a comment"))
        }
      }

      context("doc block comments") {
        var result: [TypeInfo]?

        beforeEach {
          let content =
          """
          /** This is a comment */
          protocol Foo { }
          """
          fileURL = try? Temporary.makeFile(content: content)
          result = try? sut.analyze(fileURL: fileURL)
        }

        it("contains the comment") {
          expect(result?[0].comment).to(contain("/** This is a comment */"))
        }
      }

    }
  }
}
