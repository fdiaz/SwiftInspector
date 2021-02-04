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

final class ClassVisitorSpec: QuickSpec {
  private var sut = ClassVisitor()

  override func spec() {
    beforeEach {
      self.sut = ClassVisitor()
    }

    describe("visit(_:)") {
      context("visiting a single class declaration") {
        context("with no conformance") {
          it("finds the type name") {
            let content = """
              public class SomeClass {}
              """

            try VisitorExecutor.walkVisitor(
              self.sut,
              overContent: content)

            let classInfo = self.sut.classes.first
            expect(classInfo?.name) == "SomeClass"
            expect(classInfo?.inheritsFromTypes.map { $0.asSource }) == []
            expect(classInfo?.parentType).to(beNil())
          }
        }

        context("with a single type conformance") {
          it("finds the type name") {
            let content = """
              public class SomeClass: Equatable {}
              """

            try VisitorExecutor.walkVisitor(
              self.sut,
              overContent: content)

            let classInfo = self.sut.classes.first
            expect(classInfo?.name) == "SomeClass"
            expect(classInfo?.inheritsFromTypes.map { $0.asSource }) == ["Equatable"]
            expect(classInfo?.parentType).to(beNil())
          }
        }

        context("with multiple type conformances") {
          it("finds the type name") {
            let content = """
              public class SomeClass: Foo, Bar {}
              """

            try VisitorExecutor.walkVisitor(
              self.sut,
              overContent: content)

            let classInfo = self.sut.classes.first
            expect(classInfo?.name) == "SomeClass"
            expect(classInfo?.inheritsFromTypes.map { $0.asSource }) == ["Foo", "Bar"]
            expect(classInfo?.parentType).to(beNil())
          }
        }
      }

      context("visiting a code block with nested declarations") {
        context("visiting a class with nested classes") {
          beforeEach {
            let content = """
              public class FooClass {
                public class FooClass {}
                public class BarFooClass: Equatable {
                  public class BarBarFooClass: Hashable {}
                }
                public class FooFooClass {
                  public class BarFooFoo1Class: BarFooFoo1Protocol1,
                    BarFooFoo1Protocol2
                  {
                    public class BarBarFooFoo1Class {}
                  }
                  public class BarFooFoo2Class {}
                }
              }
              """

            try? VisitorExecutor.walkVisitor(
              self.sut,
              overContent: content)
          }

          it("finds FooClass") {
            let matching = self.sut.classes.filter {
              $0.name == "FooClass"
                && $0.inheritsFromTypes.map { $0.asSource } == []
                && $0.parentType?.asSource == nil
            }

            expect(matching.count) == 1
          }

          it("finds FooClass.FooClass") {
            let matching = self.sut.classes.filter {
              $0.name == "FooClass"
                && $0.inheritsFromTypes.map { $0.asSource } == []
                && $0.parentType?.asSource == "FooClass"
            }

            expect(matching.count) == 1
          }

          it("finds BarFooClass") {
            let matching = self.sut.classes.filter {
              $0.name == "BarFooClass"
                && $0.inheritsFromTypes.map { $0.asSource } == ["Equatable"]
                && $0.parentType?.asSource == "FooClass"
            }

            expect(matching.count) == 1
          }

          it("finds BarBarFooClass") {
            let matching = self.sut.classes.filter {
              $0.name == "BarBarFooClass"
                && $0.inheritsFromTypes.map { $0.asSource } == ["Hashable"]
                && $0.parentType?.asSource == "FooClass.BarFooClass"
            }

            expect(matching.count) == 1
          }

          it("finds FooFooClass") {
            let matching = self.sut.classes.filter {
              $0.name == "FooFooClass"
                && $0.inheritsFromTypes.map { $0.asSource } == []
                && $0.parentType?.asSource == "FooClass"
            }

            expect(matching.count) == 1
          }

          it("finds BarFooFoo1Class") {
            let matching = self.sut.classes.filter {
              $0.name == "BarFooFoo1Class"
                && $0.inheritsFromTypes.map { $0.asSource } == ["BarFooFoo1Protocol1", "BarFooFoo1Protocol2"]
                && $0.parentType?.asSource == "FooClass.FooFooClass"
            }

            expect(matching.count) == 1
          }

          it("finds BarBarFooFoo1Class") {
            let matching = self.sut.classes.filter {
              $0.name == "BarBarFooFoo1Class"
                && $0.inheritsFromTypes.map { $0.asSource } == []
                && $0.parentType?.asSource == "FooClass.FooFooClass.BarFooFoo1Class"
            }

            expect(matching.count) == 1
          }

          it("finds BarFooFoo2Class") {
            let matching = self.sut.classes.filter {
              $0.name == "BarFooFoo2Class"
                && $0.inheritsFromTypes.map { $0.asSource } == []
                && $0.parentType?.asSource == "FooClass.FooFooClass"
            }

            expect(matching.count) == 1
          }
        }

        context("visiting a class with nested structs, classes, and enums") {
          beforeEach {
            let content = """
              public class FooClass {
                public struct BarFooStruct: Equatable {
                  public class BarBarFooClass {}
                }
                public enum BarFooEnum {
                  public class BarBarFooClass {}
                }
                public class FooFooClass {
                  public class BarFooFooClass {}
                }
              }
              """

            try? VisitorExecutor.walkVisitor(
              self.sut,
              overContent: content)
          }

          it("finds FooClass") {
            let matching = self.sut.classes.filter {
              $0.name == "FooClass"
                && $0.inheritsFromTypes.map { $0.asSource } == []
                && $0.parentType?.asSource == nil
            }

            expect(matching.count) == 1
          }

          it("finds FooClass.BarFooStruct") {
            let matching = self.sut.innerStructs.filter {
              $0.name == "BarFooStruct"
                && $0.inheritsFromTypes.map { $0.asSource } == ["Equatable"]
                && $0.parentType?.asSource == "FooClass"
            }

            expect(matching.count) == 1
          }

          it("finds FooClass.BarFooStruct.BarBarFooClass") {
            let matching = self.sut.classes.filter {
              $0.name == "BarBarFooClass"
                && $0.inheritsFromTypes.map { $0.asSource } == []
                && $0.parentType?.asSource == "FooClass.BarFooStruct"
            }

            expect(matching.count) == 1
          }

          it("finds FooClass.FooFooClass") {
            let matching = self.sut.classes.filter {
              $0.name == "FooFooClass"
                && $0.inheritsFromTypes.map { $0.asSource } == []
                && $0.parentType?.asSource == "FooClass"
            }

            expect(matching.count) == 1
          }

          it("finds FooClass.FooFooClass.BarFooFooClass") {
            let matching = self.sut.classes.filter {
              $0.name == "BarFooFooClass"
                && $0.inheritsFromTypes.map { $0.asSource } == []
                && $0.parentType?.asSource == "FooClass.FooFooClass"
            }

            expect(matching.count) == 1
          }

          it("finds FooClass.BarFooEnum") {
            let matching = self.sut.innerEnums.filter {
              $0.name == "BarFooEnum"
                && $0.inheritsFromTypes.map { $0.asSource } == []
                && $0.parentType?.asSource == "FooClass"
            }

            expect(matching.count) == 1
          }

          it("finds FooClass.BarFooEnum.BarBarFooClass") {
            let matching = self.sut.classes.filter {
              $0.name == "BarBarFooClass"
                && $0.inheritsFromTypes.map { $0.asSource } == []
                && $0.parentType?.asSource == "FooClass.BarFooEnum"
            }

            expect(matching.count) == 1
          }
        }
      }

      context("visiting a code block with multiple top-level declarations") {
        context("with multiple top-level classes") {
          it("asserts") {
            let content = """
            public class FooClass {}
            public class BarClass {}
            """

            // The ClassVisitor is only meant to be used over a single class.
            // Using a ClassVisitor over a block that has multiple top-level
            // classes is API misuse.
            expect(try VisitorExecutor.walkVisitor(
                    self.sut,
                    overContent: content))
              .to(throwAssertion())
          }
        }

        context("with a top-level struct after a top-level class") {
          it("asserts") {
            let content = """
            public class FooClass {}
            public struct FooStruct {}
            """

            // The ClassVisitor is only meant to be used over a single class.
            // Using a ClassVisitor over a block that has a top-level struct
            // is API misuse.
            expect(try VisitorExecutor.walkVisitor(
                    self.sut,
                    overContent: content))
              .to(throwAssertion())
          }
        }

        context("with a top-level enum after a top-level class") {
          it("asserts") {
            let content = """
            public class FooClass {}
            public struct FooEnum {}
            """

            // The ClassVisitor is only meant to be used over a single class.
            // Using a ClassVisitor over a block that has a top-level enum
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

          // The ClassVisitor is only meant to be used over a single class.
          // Using a ClassVisitor over a block that has a top-level struct
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

          // The ClassVisitor is only meant to be used over a single class.
          // Using a ClassVisitor over a block that has a top-level enum
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

          // The ClassVisitor is only meant to be used over a single class.
          // Using a ClassVisitor over a block that has a protocol
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

          // The ClassVisitor is only meant to be used over a single class.
          // Using a ClassVisitor over a block that has an extension
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
