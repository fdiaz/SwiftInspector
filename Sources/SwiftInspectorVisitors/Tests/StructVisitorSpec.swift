// Created by Dan Federman on 1/26/21.
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

import Foundation
import Nimble
import Quick
import SwiftInspectorTestHelpers

@testable import SwiftInspectorVisitors

final class StructVisitorSpec: QuickSpec {
  private var sut = StructVisitor()

  override func spec() {
    beforeEach {
      self.sut = StructVisitor()
    }

    describe("visit(_:)") {
      context("visiting a single struct declaration") {
        context("with no conformance") {
          it("finds the type name") {
            let content = """
              public struct SomeStruct {}
              """

            try VisitorExecutor.walkVisitor(
              self.sut,
              overContent: content)

            expect(self.sut.structs.first) == StructInfo(
              name: "SomeStruct",
              inheritsFromTypes: [],
              parentTypeName: nil)
          }
        }

        context("with a single type conformance") {
          it("finds the type name") {
            let content = """
              public struct SomeStruct: Equatable {}
              """

            try VisitorExecutor.walkVisitor(
              self.sut,
              overContent: content)

            expect(self.sut.structs.first) == StructInfo(
              name: "SomeStruct",
              inheritsFromTypes: ["Equatable"],
              parentTypeName: nil)
          }
        }

        context("with multiple type conformances") {
          it("finds the type name") {
            let content = """
              public struct SomeStruct: Foo, Bar {}
              """

            try VisitorExecutor.walkVisitor(
              self.sut,
              overContent: content)

            expect(self.sut.structs.first) == StructInfo(
              name: "SomeStruct",
              inheritsFromTypes: ["Foo", "Bar"],
              parentTypeName: nil)
          }
        }
      }

      context("visiting a code block with nested declarations") {
        context("visiting a struct with nested structs") {
          it("finds all nested structs") {
            let content = """
              public struct FooStruct {
                public struct BarFooStruct: Equatable {
                  public struct BarBarFooStruct: Hashable {}
                }
                public struct FooFooStruct {
                  public struct BarFooFoo1Struct: BarFooFoo1Protocol1,
                    BarFooFoo1Protocol2
                  {
                    public struct BarBarFooFoo1Struct {}
                  }
                  public struct BarFooFoo2Struct {}
                }
              }
              """

            try VisitorExecutor.walkVisitor(
              self.sut,
              overContent: content)

            expect(self.sut.structs) == [
              StructInfo(
                name: "FooStruct",
                inheritsFromTypes: [],
                parentTypeName: nil),
              StructInfo(
                name: "BarFooStruct",
                inheritsFromTypes: ["Equatable"],
                parentTypeName: "FooStruct"),
              StructInfo(
                name: "BarBarFooStruct",
                inheritsFromTypes: ["Hashable"],
                parentTypeName: "FooStruct.BarFooStruct"),
              StructInfo(
                name: "FooFooStruct",
                inheritsFromTypes: [],
                parentTypeName: "FooStruct"),
              StructInfo(
                name: "BarFooFoo1Struct",
                inheritsFromTypes: ["BarFooFoo1Protocol1", "BarFooFoo1Protocol2"],
                parentTypeName: "FooStruct.FooFooStruct"),
              StructInfo(
                name: "BarBarFooFoo1Struct",
                inheritsFromTypes: [],
                parentTypeName: "FooStruct.FooFooStruct.BarFooFoo1Struct"),
              StructInfo(
                name: "BarFooFoo2Struct",
                inheritsFromTypes: [],
                parentTypeName: "FooStruct.FooFooStruct"),
            ]
          }
        }

        context("visiting a struct with nested structs, classes, and enums") {
          it("finds all nested structs") { // TODO: find classes and enums as well
            let content = """
              public struct FooStruct {
                public class BarFooClass: Equatable {
                  public struct BarBarFooStruct {} // TODO: find this struct
                }
                public enum BarFooEnum {
                  public struct BarBarFooStruct {} // TODO: find this struct
                }
                public struct FooFooStruct {
                  public struct BarFooFooStruct {}
                }
              }
              """

            try VisitorExecutor.walkVisitor(
              self.sut,
              overContent: content)

            expect(self.sut.structs) == [
              StructInfo(
                name: "FooStruct",
                inheritsFromTypes: [],
                parentTypeName: nil),
              StructInfo(
                name: "FooFooStruct",
                inheritsFromTypes: [],
                parentTypeName: "FooStruct"),
              StructInfo(
                name: "BarFooFooStruct",
                inheritsFromTypes: [],
                parentTypeName: "FooStruct.FooFooStruct"),
            ]
          }
        }
      }

      context("visiting a code block with multiple top-level declarations") {
        context("with multiple top-level structs") {
          it("asserts") {
            let content = """
            public struct FooStruct {}
            public struct BarStruct {}
            """

            // The StructVisitor is only meant to be used over a single struct.
            // Using a StructVisitor over a block that has multiple top-level
            // structs is API misuse.
            expect(try VisitorExecutor.walkVisitor(
                    self.sut,
                    overContent: content))
              .to(throwAssertion())
          }
        }

        context("with a top-level class after a top-level struct") {
          it("asserts") {
            let content = """
            public struct FooStruct {}
            public struct FooClass {}
            """

            // The StructVisitor is only meant to be used over a single struct.
            // Using a StructVisitor over a block that has a top-level class
            // is API misuse.
            expect(try VisitorExecutor.walkVisitor(
                    self.sut,
                    overContent: content))
              .to(throwAssertion())
          }
        }

        context("with a top-level enum after a top-level struct") {
          it("asserts") {
            let content = """
            public struct FooStruct {}
            public struct FooEnum {}
            """

            // The StructVisitor is only meant to be used over a single struct.
            // Using a StructVisitor over a block that has a top-level enum
            // is API misuse.
            expect(try VisitorExecutor.walkVisitor(
                    self.sut,
                    overContent: content))
              .to(throwAssertion())
          }
        }
      }

      context("visiting a code block with a top-level class declaration") {
        it("asserts") {
          let content = """
            public class FooClass {}
            """

          // The StructVisitor is only meant to be used over a single struct.
          // Using a StructVisitor over a block that has a top-level class
          // is API misuse.
          expect(try VisitorExecutor.walkVisitor(
                  self.sut,
                  overContent: content))
            .to(throwAssertion())
        }
      }

      context("visiting a code block with a top-level enum declaration") {
        it("asserts") {
          let content = """
            public enum FooEnum {}
            """

          // The StructVisitor is only meant to be used over a single struct.
          // Using a StructVisitor over a block that has a top-level enum
          // is API misuse.
          expect(try VisitorExecutor.walkVisitor(
                  self.sut,
                  overContent: content))
            .to(throwAssertion())
        }
      }
    }
  }
}
