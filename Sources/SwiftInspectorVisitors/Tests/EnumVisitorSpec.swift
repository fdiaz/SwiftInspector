// Created by Dan Federman on 1/29/21.
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

final class EnumVisitorSpec: QuickSpec {
  private var sut = EnumVisitor()

  override func spec() {
    beforeEach {
      self.sut = EnumVisitor()
    }

    describe("visit(_:)") {
      context("visiting a single enum declaration") {
        context("with no conformance") {
          it("finds the type name") {
            let content = """
              public enum SomeEnum {}
              """

            try VisitorExecutor.walkVisitor(
              self.sut,
              overContent: content)

            let classInfo = self.sut.enums.first
            expect(classInfo?.name) == "SomeEnum"
            expect(classInfo?.inheritsFromTypes) == []
            expect(classInfo?.parentTypeName).to(beNil())
          }
        }

        context("with a single type conformance") {
          it("finds the type name") {
            let content = """
              public enum SomeEnum: Equatable {}
              """

            try VisitorExecutor.walkVisitor(
              self.sut,
              overContent: content)

            let classInfo = self.sut.enums.first
            expect(classInfo?.name) == "SomeEnum"
            expect(classInfo?.inheritsFromTypes) == ["Equatable"]
            expect(classInfo?.parentTypeName).to(beNil())
          }
        }

        context("with multiple type conformances") {
          it("finds the type name") {
            let content = """
              public enum SomeEnum: Foo, Bar {}
              """

            try VisitorExecutor.walkVisitor(
              self.sut,
              overContent: content)

            let classInfo = self.sut.enums.first
            expect(classInfo?.name) == "SomeEnum"
            expect(classInfo?.inheritsFromTypes) == ["Foo", "Bar"]
            expect(classInfo?.parentTypeName).to(beNil())
          }
        }
      }

      context("visiting a code block with nested declarations") {
        context("visiting a enum with nested enums") {
          beforeEach {
            let content = """
              public enum FooEnum {
                public enum BarFooEnum: Equatable {
                  public enum BarBarFooEnum: Hashable {}
                }
                public enum FooFooEnum {
                  public enum BarFooFoo1Enum: BarFooFoo1Protocol1,
                    BarFooFoo1Protocol2
                  {
                    public enum BarBarFooFoo1Enum {}
                  }
                  public enum BarFooFoo2Enum {}
                }
              }
              """

            try? VisitorExecutor.walkVisitor(
              self.sut,
              overContent: content)
          }

          it("finds FooEnum") {
            let matching = self.sut.enums.filter {
              $0.name == "FooEnum"
                && $0.inheritsFromTypes == []
                && $0.parentTypeName == nil
            }
            expect(matching.count) == 1
          }

          it("finds BarFooEnum") {
            let matching = self.sut.enums.filter {
              $0.name == "BarFooEnum"
                && $0.inheritsFromTypes == ["Equatable"]
                && $0.parentTypeName == "FooEnum"
            }
            expect(matching.count) == 1
          }

          it("finds BarBarFooEnum") {
            let matching = self.sut.enums.filter {
              $0.name == "BarBarFooEnum"
                && $0.inheritsFromTypes == ["Hashable"]
                && $0.parentTypeName == "FooEnum.BarFooEnum"
            }
            expect(matching.count) == 1
          }

          it("finds FooFooEnum") {
            let matching = self.sut.enums.filter {
              $0.name == "FooFooEnum"
                && $0.inheritsFromTypes == []
                && $0.parentTypeName == "FooEnum"
            }
            expect(matching.count) == 1
          }

          it("finds BarFooFoo1Enum") {
            let matching = self.sut.enums.filter {
              $0.name == "BarFooFoo1Enum"
                && $0.inheritsFromTypes == ["BarFooFoo1Protocol1", "BarFooFoo1Protocol2"]
                && $0.parentTypeName == "FooEnum.FooFooEnum"
            }
            expect(matching.count) == 1
          }

          it("finds BarBarFooFoo1Enum") {
            let matching = self.sut.enums.filter {
              $0.name == "BarBarFooFoo1Enum"
                && $0.inheritsFromTypes == []
                && $0.parentTypeName == "FooEnum.FooFooEnum.BarFooFoo1Enum"
            }
            expect(matching.count) == 1
          }

          it("finds BarFooFoo2Enum") {
            let matching = self.sut.enums.filter {
              $0.name == "BarFooFoo2Enum"
                && $0.inheritsFromTypes == []
                && $0.parentTypeName == "FooEnum.FooFooEnum"
            }
            expect(matching.count) == 1
          }
        }

        context("visiting a enum with nested structs, classes, and enums") {
          beforeEach {
            let content = """
              public enum FooEnum {
                public enum FooEnum {}
                public struct BarFooStruct {
                  public enum BarBarFooEnum {}
                }
                public enum BarFooEnum: Equatable {
                  public enum BarBarFooEnum {}
                }
                public class FooFooClass {
                  public enum BarFooFooEnum {}
                }
              }
              """

            try? VisitorExecutor.walkVisitor(
              self.sut,
              overContent: content)
          }

          it("finds FooEnum") {
            let matching = self.sut.enums.filter {
              $0.name == "FooEnum"
                && $0.inheritsFromTypes == []
                && $0.parentTypeName == nil
            }
            expect(matching.count) == 1
          }

          it("finds FooEnum.FooEnum") {
            let matching = self.sut.enums.filter {
              $0.name == "FooEnum"
                && $0.inheritsFromTypes.map { $0.description } == []
                && $0.parentTypeName == "FooEnum"
            }
            expect(matching.count) == 1
          }

          it("finds FooEnum.BarFooStruct") {
            let matching = self.sut.innerStructs.filter {
              $0.name == "BarFooStruct"
                && $0.inheritsFromTypes == []
                && $0.parentTypeName == "FooEnum"
            }
            expect(matching.count) == 1
          }

          it("finds FooEnum.BarFooEnum") {
            let matching = self.sut.enums.filter {
              $0.name == "BarFooEnum"
                && $0.inheritsFromTypes == ["Equatable"]
                && $0.parentTypeName == "FooEnum"
            }
            expect(matching.count) == 1
          }

          it("finds FooEnum.BarFooEnum.BarBarFooEnum") {
            let matching = self.sut.enums.filter {
              $0.name == "BarBarFooEnum"
                && $0.inheritsFromTypes == []
                && $0.parentTypeName == "FooEnum.BarFooEnum"
            }
            expect(matching.count) == 1
          }

          it("finds FooEnum.BarFooStruct.BarBarFooEnum") {
            let matching = self.sut.enums.filter {
              $0.name == "BarBarFooEnum"
                && $0.inheritsFromTypes == []
                && $0.parentTypeName == "FooEnum.BarFooStruct"
            }
            expect(matching.count) == 1
          }

          it("finds FooEnum.FooFooClass") {
            let matching = self.sut.innerClasses.filter {
              $0.name == "FooFooClass"
                && $0.inheritsFromTypes == []
                && $0.parentTypeName == "FooEnum"
            }
            expect(matching.count) == 1
          }

          it("finds FooEnum.FooFooClass.BarFooFooEnum") {
            let matching = self.sut.enums.filter {
              $0.name == "BarFooFooEnum"
                && $0.inheritsFromTypes == []
                && $0.parentTypeName == "FooEnum.FooFooClass"
            }
            expect(matching.count) == 1
          }
        }
      }

      context("visiting a code block with multiple top-level declarations") {
        context("with multiple top-level enums") {
          it("asserts") {
            let content = """
            public enum FooEnum {}
            public enum BarEnum {}
            """

            // The EnumVisitor is only meant to be used over a single enum.
            // Using a EnumVisitor over a block that has multiple top-level
            // classes is API misuse.
            expect(try VisitorExecutor.walkVisitor(
                    self.sut,
                    overContent: content))
              .to(throwAssertion())
          }
        }

        context("with a top-level struct after a top-level enum") {
          it("asserts") {
            let content = """
            public enum FooEnum {}
            public struct FooStruct {}
            """

            // The EnumVisitor is only meant to be used over a single enum.
            // Using a EnumVisitor over a block that has a top-level struct
            // is API misuse.
            expect(try VisitorExecutor.walkVisitor(
                    self.sut,
                    overContent: content))
              .to(throwAssertion())
          }
        }

        context("with a top-level class after a top-level enum") {
          it("asserts") {
            let content = """
            public enum FooEnum {}
            public class FooClass {}
            """

            // The EnumVisitor is only meant to be used over a single enum.
            // Using a EnumVisitor over a block that has a top-level class
            // is API misuse.
            expect(try VisitorExecutor.walkVisitor(
                    self.sut,
                    overContent: content))
              .to(throwAssertion())
          }
        }
      }

      context("visiting a code block with a top-level struct declaration") {
        it("asserts") {
          let content = """
            public struct FooStruct {}
            """

          // The EnumVisitor is only meant to be used over a single enum.
          // Using a EnumVisitor over a block that has a top-level struct
          // is API misuse.
          expect(try VisitorExecutor.walkVisitor(
                  self.sut,
                  overContent: content))
            .to(throwAssertion())
        }
      }

      context("visiting a code block with a top-level class declaration") {
        it("asserts") {
          let content = """
            public class FooClass {}
            """

          // The EnumVisitor is only meant to be used over a single enum.
          // Using a EnumVisitor over a block that has a top-level enum
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

          // The EnumVisitor is only meant to be used over a single enum.
          // Using a EnumVisitor over a block that has a top-level protocol
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

          // The EnumVisitor is only meant to be used over a single enum.
          // Using a EnumVisitor over a block that has an extension
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
