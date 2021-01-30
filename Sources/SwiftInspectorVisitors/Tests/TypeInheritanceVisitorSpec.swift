// Created by Dan Federman on 1/27/21.
//
// Copyright © 2021 Dan Federman
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
import SwiftInspectorTestHelpers

@testable import SwiftInspectorVisitors

final class TypeInheritanceVisitorSpec: QuickSpec {
  private var sut = TypeInheritanceVisitor()
  
  override func spec() {
    beforeEach {
      self.sut = TypeInheritanceVisitor()
    }

    describe("visit(_:)") {
      context("when a type conforms to a protocol") {
        context("with only one conformance") {
          beforeEach {
            let content = """
            class SomeObject: Foo {}
            """
            try? VisitorExecutor.walkVisitor(self.sut, overContent: content)
          }

          it("returns the conforming type name") {
            expect(self.sut.inheritsFromTypes) == ["Foo"]
          }
        }

        context("with one fully-qualified conformance") {
          beforeEach {
            let content = """
            class SomeObject: Swift.Equatable {}
            """
            try? VisitorExecutor.walkVisitor(self.sut, overContent: content)
          }

          it("returns the conforming type name") {
            expect(self.sut.inheritsFromTypes) == ["Swift.Equatable"]
          }
        }

        context("with multiple conformances on the same line") {
          beforeEach {
            let content = """
            class SomeObject: Foo, Bar, FooBar {}
            """
            try? VisitorExecutor.walkVisitor(self.sut, overContent: content)
          }

          it("returns the conforming type names") {
            expect(self.sut.inheritsFromTypes) == ["Foo", "Bar", "FooBar"]
          }
        }

        context("with multiple conformances on multiple lines") {
          beforeEach {
            let content = """
            class SomeObject: Foo, Bar,
              FooBar {}
            """
            try? VisitorExecutor.walkVisitor(self.sut, overContent: content)
          }

          it("returns the conforming type names") {
            expect(self.sut.inheritsFromTypes) == ["Foo", "Bar", "FooBar"]
          }
        }
      }

      context("when an inner type conforms to a protocol but the outer type does not") {
        beforeEach {
          let content = """
          class SomeObject {
            struct SomeStruct: Foo {}
          }
          """
          try? VisitorExecutor.walkVisitor(self.sut, overContent: content)
        }

        it("does not find the inner type's conformance the conforming type names") {
          expect(self.sut.inheritsFromTypes).to(beEmpty())
        }
      }

      context("when both an outer and inner type conform to a protocol") {
        beforeEach {
          let content = """
          class SomeObject: Bar {
            struct SomeStruct: Foo {}
          }
          """
          try? VisitorExecutor.walkVisitor(self.sut, overContent: content)
        }

        it("only finds the outer type's conformance") {
          expect(self.sut.inheritsFromTypes) == ["Bar"]
        }
      }
    }
  }
}
