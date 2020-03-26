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

import Nimble
import Quick
import Foundation

@testable import SwiftInspectorCore

final class TypealiasAnalyzerSpec: QuickSpec {
  override func spec() {
    var fileURL: URL!
    var sut = TypealiasAnalyzer()

    beforeEach {
      sut = TypealiasAnalyzer()
    }

    afterEach {
      guard let fileURL = fileURL else {
        return
      }
      try? Temporary.removeItem(at: fileURL)
    }

    describe("analyze(fileURL:)") {
      context("when there is no typealias statement") {
        it("returns an empty array") {
          fileURL = try! Temporary.makeFile(
            content: """
                     final class SomeClass {}
                     """
          )

          let result = try? sut.analyze(fileURL: fileURL)
          expect(result).to(beEmpty())
        }
      }

      context("with a single typealias statement") {
        beforeEach {
          fileURL = try! Temporary.makeFile(
            content: """
                     typealias SomeTypealias = TypeA & TypeB
                     """
          )
        }

        it("returns the name of the typelias") {
          let result = try? sut.analyze(fileURL: fileURL)
          expect(result?.first?.name) == "SomeTypealias"
        }

        it("returns the identifiers") {
          let result = try? sut.analyze(fileURL: fileURL)
          expect(result?.first?.identifiers) == ["TypeA", "TypeB"]
        }
      }

      context("with multiple typealias statements") {
        beforeEach {
          fileURL = try! Temporary.makeFile(
            content: """
                     final class Some {
                       typealias SomeTypealias = SomeType & SomeOtherType
                     }

                     typealias AnotherTypealias = AnotherType
                     """
          )
        }

        it("returns all the names of the typeliases") {
          let result = try? sut.analyze(fileURL: fileURL)
          expect(result?.first?.name) == "SomeTypealias"
          expect(result?.last?.name) == "AnotherTypealias"
        }

        it("returns the identifiers") {
          let result = try? sut.analyze(fileURL: fileURL)
          expect(result?.first?.identifiers) == ["SomeType", "SomeOtherType"]
          expect(result?.last?.identifiers) == ["AnotherType"]
        }
      }

    }
  }
}
