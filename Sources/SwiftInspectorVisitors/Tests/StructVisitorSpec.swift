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

            let structInfo = self.sut.structs.first
            expect(structInfo?.name) == "SomeStruct"
            expect(structInfo?.inheritsFromTypes.map { $0.description }) == []
            expect(structInfo?.parentType).to(beNil())
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

            let structInfo = self.sut.structs.first
            expect(structInfo?.name) == "SomeStruct"
            expect(structInfo?.inheritsFromTypes.map { $0.description }) == ["Equatable"]
            expect(structInfo?.parentType).to(beNil())
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

            let structInfo = self.sut.structs.first
            expect(structInfo?.name) == "SomeStruct"
            expect(structInfo?.inheritsFromTypes.map { $0.description }) == ["Foo", "Bar"]
            expect(structInfo?.parentType).to(beNil())
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
            let matching = self.sut.structs.filter {
              $0.name == "FooStruct"
                && $0.inheritsFromTypes.map { $0.description } == []
                && $0.parentType?.description == nil
            }

            expect(matching.count) == 1
          }

          it("finds BarFooStruct") {
            let matching = self.sut.structs.filter {
              $0.name == "BarFooStruct"
                && $0.inheritsFromTypes.map { $0.description } == ["Equatable"]
                && $0.parentType?.description == "FooStruct"
            }

            expect(matching.count) == 1
          }

          it("finds BarBarFooStruct") {
            let matching = self.sut.structs.filter {
              $0.name == "BarBarFooStruct"
                && $0.inheritsFromTypes.map { $0.description } == ["Hashable"]
                && $0.parentType?.description == "FooStruct.BarFooStruct"
            }

            expect(matching.count) == 1
          }

          it("finds FooFooStruct") {
            let matching = self.sut.structs.filter {
              $0.name == "FooFooStruct"
                && $0.inheritsFromTypes.map { $0.description } == []
                && $0.parentType?.description == "FooStruct"
            }

            expect(matching.count) == 1
          }

          it("finds BarFooFoo1Struct") {
            let matching = self.sut.structs.filter {
              $0.name == "BarFooFoo1Struct"
                && $0.inheritsFromTypes.map { $0.description } == ["BarFooFoo1Protocol1", "BarFooFoo1Protocol2"]
                && $0.parentType?.description == "FooStruct.FooFooStruct"
            }

            expect(matching.count) == 1
          }

          it("finds BarBarFooFoo1Struct") {
            let matching = self.sut.structs.filter {
              $0.name == "BarBarFooFoo1Struct"
                && $0.inheritsFromTypes.map { $0.description } == []
                && $0.parentType?.description == "FooStruct.FooFooStruct.BarFooFoo1Struct"
            }

            expect(matching.count) == 1
          }

          it("finds BarFooFoo2Struct") {
            let matching = self.sut.structs.filter {
              $0.name == "BarFooFoo2Struct"
                && $0.inheritsFromTypes.map { $0.description } == []
                && $0.parentType?.description == "FooStruct.FooFooStruct"
            }

            expect(matching.count) == 1
          }
        }

        context("visiting a struct with nested structs, classes, and enums") {
          beforeEach {
            let content = """
              public struct FooStruct {
                public struct FooStruct {}
                public class BarFooClass: Equatable {
                  public struct BarBarFooStruct {}
                }
                public enum BarFooEnum {
                  public struct BarBarFooStruct {}
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
            let matching = self.sut.structs.filter {
              $0.name == "FooStruct"
                && $0.inheritsFromTypes.map { $0.description } == []
                && $0.parentType?.description == nil
            }

            expect(matching.count) == 1
          }

          it("finds FooStruct.FooStruct") {
            let matching = self.sut.structs.filter {
              $0.name == "FooStruct"
                && $0.inheritsFromTypes.map { $0.description } == []
                && $0.parentType?.description == "FooStruct"
            }

            expect(matching.count) == 1
          }

          it("finds FooStruct.FooFooStruct") {
            let matching = self.sut.structs.filter {
              $0.name == "FooFooStruct"
                && $0.inheritsFromTypes.map { $0.description } == []
                && $0.parentType?.description == "FooStruct"
            }

            expect(matching.count) == 1
          }

          it("finds FooStruct.FooFooStruct.BarFooFooStruct") {
            let matching = self.sut.structs.filter {
              $0.name == "BarFooFooStruct"
                && $0.inheritsFromTypes.map { $0.description } == []
                && $0.parentType?.description == "FooStruct.FooFooStruct"
            }

            expect(matching.count) == 1
          }

          it("finds FooStruct.BarFooClass") {
            let matching = self.sut.innerClasses.filter {
              $0.name == "BarFooClass"
                && $0.inheritsFromTypes.map { $0.description } == ["Equatable"]
                && $0.parentType?.description == "FooStruct"
            }

            expect(matching.count) == 1
          }

          it("finds FooStruct.BarFooClass.BarBarFooStruct") {
            let matching = self.sut.structs.filter {
              $0.name == "BarBarFooStruct"
                && $0.inheritsFromTypes.map { $0.description } == []
                && $0.parentType?.description == "FooStruct.BarFooClass"
            }

            expect(matching.count) == 1
          }

          it("finds FooStruct.BarFooEnum") {
            let matching = self.sut.innerEnums.filter {
              $0.name == "BarFooEnum"
                && $0.inheritsFromTypes.map { $0.description } == []
                && $0.parentType?.description == "FooStruct"
            }

            expect(matching.count) == 1
          }

          it("finds FooStruct.BarFooEnum.BarBarFooStruct") {
            let matching = self.sut.structs.filter {
              $0.name == "BarBarFooStruct"
                && $0.inheritsFromTypes.map { $0.description } == []
                && $0.parentType?.description == "FooStruct.BarFooEnum"
            }

            expect(matching.count) == 1
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

      context("visiting a code block with a protocol declaration") {
        it("asserts") {
          let content = """
            public protocol FooProtocol {}
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

      context("visiting a code block with an extension declaration") {
         it("asserts") {
           let content = """
             public extension Array {}
             """

           // The StructVisitor is only meant to be used over a single struct.
           // Using a StructVisitor over a block that has an extension
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
