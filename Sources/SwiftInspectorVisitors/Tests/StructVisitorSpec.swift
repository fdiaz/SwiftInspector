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
          beforeEach {
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

            try? VisitorExecutor.walkVisitor(
              self.sut,
              overContent: content)
          }

          it("finds FooStruct") {
            guard self.sut.structs.count > 0 else {
              fail("FooStruct not found at expected index")
              return
            }
            let structInfo = self.sut.structs[0]
            expect(structInfo.name) == "FooStruct"
            expect(structInfo.inheritsFromTypes) == []
            expect(structInfo.parentTypeName).to(beNil())
          }

          it("finds BarFooStruct") {
            guard self.sut.structs.count > 1 else {
              fail("BarFooStruct not found at expected index")
              return
            }
            let structInfo = self.sut.structs[1]
            expect(structInfo.name) == "BarFooStruct"
            expect(structInfo.inheritsFromTypes) == ["Equatable"]
            expect(structInfo.parentTypeName) == "FooStruct"
          }

          it("finds BarBarFooStruct") {
            guard self.sut.structs.count > 2 else {
              fail("BarBarFooStruct not found at expected index")
              return
            }
            let structInfo = self.sut.structs[2]
            expect(structInfo.name) == "BarBarFooStruct"
            expect(structInfo.inheritsFromTypes) == ["Hashable"]
            expect(structInfo.parentTypeName) == "FooStruct.BarFooStruct"
          }

          it("finds FooFooStruct") {
            guard self.sut.structs.count > 3 else {
              fail("FooFooStruct not found at expected index")
              return
            }
            let structInfo = self.sut.structs[3]
            expect(structInfo.name) == "FooFooStruct"
            expect(structInfo.inheritsFromTypes) == []
            expect(structInfo.parentTypeName) == "FooStruct"
          }

          it("finds BarFooFoo1Struct") {
            guard self.sut.structs.count > 4 else {
              fail("BarFooFoo1Struct not found at expected index")
              return
            }
            let structInfo = self.sut.structs[4]
            expect(structInfo.name) == "BarFooFoo1Struct"
            expect(structInfo.inheritsFromTypes) == ["BarFooFoo1Protocol1", "BarFooFoo1Protocol2"]
            expect(structInfo.parentTypeName) == "FooStruct.FooFooStruct"
          }

          it("finds BarBarFooFoo1Struct") {
            guard self.sut.structs.count > 5 else {
              fail("BarBarFooFoo1Struct not found at expected index")
              return
            }
            let structInfo = self.sut.structs[5]
            expect(structInfo.name) == "BarBarFooFoo1Struct"
            expect(structInfo.inheritsFromTypes) == []
            expect(structInfo.parentTypeName) == "FooStruct.FooFooStruct.BarFooFoo1Struct"
          }

          it("finds BarFooFoo2Struct") {
            guard self.sut.structs.count > 6 else {
              fail("BarFooFoo2Struct not found at expected index")
              return
            }
            let structInfo = self.sut.structs[6]
            expect(structInfo.name) == "BarFooFoo2Struct"
            expect(structInfo.inheritsFromTypes) == []
            expect(structInfo.parentTypeName) == "FooStruct.FooFooStruct"
          }
        }

        context("visiting a struct with nested structs, classes, and enums") {
          beforeEach { // TODO: find classes and enums as well
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

            try? VisitorExecutor.walkVisitor(
              self.sut,
              overContent: content)
          }

          it("finds FooStruct") {
            guard self.sut.structs.count > 0 else {
              fail("FooStruct not found at expected index")
              return
            }
            let structInfo = self.sut.structs[0]
            expect(structInfo.name) == "FooStruct"
            expect(structInfo.inheritsFromTypes) == []
            expect(structInfo.parentTypeName).to(beNil())
          }

          it("finds FooFooStruct") {
            guard self.sut.structs.count > 1 else {
              fail("FooFooStruct not found at expected index")
              return
            }
            let structInfo = self.sut.structs[1]
            expect(structInfo.name) == "FooFooStruct"
            expect(structInfo.inheritsFromTypes) == []
            expect(structInfo.parentTypeName) == "FooStruct"
          }

          it("finds BarFooFooStruct") {
            guard self.sut.structs.count > 2 else {
              fail("BarFooFooStruct not found at expected index")
              return
            }
            let structInfo = self.sut.structs[2]
            expect(structInfo.name) == "BarFooFooStruct"
            expect(structInfo.inheritsFromTypes) == []
            expect(structInfo.parentTypeName) == "FooStruct.FooFooStruct"
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
