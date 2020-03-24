// Created by Francisco Diaz on 10/14/19.
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

@testable import SwiftInspectorKit

final class TypeConformanceAnalyzerSpec: QuickSpec {
  private var fileURL: URL!

  override func spec() {
    afterEach {
      guard let fileURL = self.fileURL else {
        return
      }
      try? Temporary.removeItem(at: fileURL)
    }

    describe("analyze(fileURL:)") {

      context("when a type conforms to a protocol") {
        context("with only one conformance") {
          it("conforms") {
            let content = """
            protocol Some {}

            class Another: Some {}
            """

            self.fileURL = try? Temporary.makeFile(content: content)

            let sut = TypeConformanceAnalyzer(typeName: "Some")
            let result = try? sut.analyze(fileURL: self.fileURL)

            expect(result?.doesConform) == true
          }

          context("when the type has multiple conformances") {
            it("conforms") {
              let content = """
              protocol Foo {}
              protocol Bar {}

              class Another: Foo, Bar {}

              class Second: Foo {}
              """

              self.fileURL = try? Temporary.makeFile(content: content)

              let sut = TypeConformanceAnalyzer(typeName: "Bar")
              let result = try? sut.analyze(fileURL: self.fileURL)

              expect(result?.doesConform) == true
            }
          }

          context("when the types conform in a different line") {
            it("conforms") {
              let content = """
              protocol A {}
              protocol B {}
              protocol C {}

              class Another: A
              ,B, C  {}
              """

              self.fileURL = try? Temporary.makeFile(content: content)

              let sut = TypeConformanceAnalyzer(typeName: "B")
              let result = try? sut.analyze(fileURL: self.fileURL)

              expect(result?.doesConform) == true
            }
          }

        }
      }

      context("when a type implements a subclass") {
        it("is marked as conforms") {
          let content = """
          open class Some {}

          class Another: Some {}
          """

          self.fileURL = try? Temporary.makeFile(content: content)

          let sut = TypeConformanceAnalyzer(typeName: "Some")
          let result = try? sut.analyze(fileURL: self.fileURL)

          expect(result?.doesConform) == true
        }
      }

      context("when the type is not present") {
        it("is not marked as conforms") {
          let content = """
          protocol Some {}

          class Another: Some {}
          """

          self.fileURL = try? Temporary.makeFile(content: content)

          let sut = TypeConformanceAnalyzer(typeName: "AnotherType")
          let result = try? sut.analyze(fileURL: self.fileURL)

          expect(result?.doesConform) == false
        }
      }

    }
  }

}
