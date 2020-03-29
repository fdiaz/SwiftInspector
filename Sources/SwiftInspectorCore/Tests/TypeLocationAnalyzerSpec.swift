// Created by Michael Bachand on 3/28/20.
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

final class TypeLocationAnalyzerSpec: QuickSpec {

  override func spec() {
    var fileURL: URL!

    afterEach {
      guard let fileURL = fileURL else {
        return
      }
      try? Temporary.removeItem(at: fileURL)
    }

    describe("analyze(fileURL:)") {
      context("the type is not present") {
        let content =
        """
        import Foundation
        """
        fileURL = try? Temporary.makeFile(content: content)

        it("returns nil") {
          let sut = TypeLocationAnalyzer(typeName: "Foo")
          let result = try? sut.analyze(fileURL: fileURL)

          expect(result).to(beNil())
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

        it("returns type location") {
          let sut = TypeLocationAnalyzer(typeName: "Foo")
          let result = try? sut.analyze(fileURL: fileURL)

          expect(result).notTo(beNil())
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

        it("returns type location") {
          let sut = TypeLocationAnalyzer(typeName: "Foo")
          let result = try? sut.analyze(fileURL: fileURL)

          expect(result).notTo(beNil())
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

        it("returns type location") {
          let sut = TypeLocationAnalyzer(typeName: "Foo")
          let result = try? sut.analyze(fileURL: fileURL)

          expect(result).notTo(beNil())
        }
      }
    }
  }
}
