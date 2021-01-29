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
            expect(classInfo?.inheritsFromTypes) == []
            expect(classInfo?.parentTypeName).to(beNil())
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
            expect(classInfo?.inheritsFromTypes) == ["Equatable"]
            expect(classInfo?.parentTypeName).to(beNil())
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
            expect(classInfo?.inheritsFromTypes) == ["Foo", "Bar"]
            expect(classInfo?.parentTypeName).to(beNil())
          }
        }
      }

      context("visiting a code block with nested declarations") {
        context("visiting a class with nested classes") {
          beforeEach {
            let content = """
              public class FooClass {
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
            guard self.sut.classes.count > 0 else {
              fail("FooClass not found at expected index")
              return
            }
            let classInfo = self.sut.classes[0]
            expect(classInfo.name) == "FooClass"
            expect(classInfo.inheritsFromTypes) == []
            expect(classInfo.parentTypeName).to(beNil())
          }

          it("finds BarFooClass") {
            guard self.sut.classes.count > 1 else {
              fail("BarFooClass not found at expected index")
              return
            }
            let classInfo = self.sut.classes[1]
            expect(classInfo.name) == "BarFooClass"
            expect(classInfo.inheritsFromTypes) == ["Equatable"]
            expect(classInfo.parentTypeName) == "FooClass"
          }

          it("finds BarBarFooClass") {
            guard self.sut.classes.count > 2 else {
              fail("BarBarFooClass not found at expected index")
              return
            }
            let classInfo = self.sut.classes[2]
            expect(classInfo.name) == "BarBarFooClass"
            expect(classInfo.inheritsFromTypes) == ["Hashable"]
            expect(classInfo.parentTypeName) == "FooClass.BarFooClass"
          }

          it("finds FooFooClass") {
            guard self.sut.classes.count > 3 else {
              fail("FooFooClass not found at expected index")
              return
            }
            let classInfo = self.sut.classes[3]
            expect(classInfo.name) == "FooFooClass"
            expect(classInfo.inheritsFromTypes) == []
            expect(classInfo.parentTypeName) == "FooClass"
          }

          it("finds BarFooFoo1Class") {
            guard self.sut.classes.count > 4 else {
              fail("BarFooFoo1Class not found at expected index")
              return
            }
            let classInfo = self.sut.classes[4]
            expect(classInfo.name) == "BarFooFoo1Class"
            expect(classInfo.inheritsFromTypes) == ["BarFooFoo1Protocol1", "BarFooFoo1Protocol2"]
            expect(classInfo.parentTypeName) == "FooClass.FooFooClass"
          }

          it("finds BarBarFooFoo1Class") {
            guard self.sut.classes.count > 5 else {
              fail("BarBarFooFoo1Class not found at expected index")
              return
            }
            let classInfo = self.sut.classes[5]
            expect(classInfo.name) == "BarBarFooFoo1Class"
            expect(classInfo.inheritsFromTypes) == []
            expect(classInfo.parentTypeName) == "FooClass.FooFooClass.BarFooFoo1Class"
          }

          it("finds BarFooFoo2Class") {
            guard self.sut.classes.count > 6 else {
              fail("BarFooFoo2Class not found at expected index")
              return
            }
            let classInfo = self.sut.classes[6]
            expect(classInfo.name) == "BarFooFoo2Class"
            expect(classInfo.inheritsFromTypes) == []
            expect(classInfo.parentTypeName) == "FooClass.FooFooClass"
          }
        }

        context("visiting a class with nested structs, classes, and enums") {
          beforeEach { // TODO: enums as well
            let content = """
              public class FooClass {
                public struct BarFooStruct: Equatable {
                  public class BarBarFooClass {}
                }
                public enum BarFooEnum {
                  public class BarBarFooClass {} // TODO: find this class
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
            guard self.sut.classes.count > 0 else {
              fail("FooClass not found at expected index")
              return
            }
            let classInfo = self.sut.classes[0]
            expect(classInfo.name) == "FooClass"
            expect(classInfo.inheritsFromTypes) == []
            expect(classInfo.parentTypeName).to(beNil())
          }

          it("finds BarBarFooClass") {
            guard self.sut.classes.count > 1 else {
              fail("BarBarFooClass not found at expected index")
              return
            }
            let classInfo = self.sut.classes[1]
            expect(classInfo.name) == "BarBarFooClass"
            expect(classInfo.inheritsFromTypes) == []
            expect(classInfo.parentTypeName) == "FooClass.BarFooStruct"
          }

          it("finds FooFooClass") {
            guard self.sut.classes.count > 2 else {
              fail("FooFooClass not found at expected index")
              return
            }
            let classInfo = self.sut.classes[2]
            expect(classInfo.name) == "FooFooClass"
            expect(classInfo.inheritsFromTypes) == []
            expect(classInfo.parentTypeName) == "FooClass"
          }

          it("finds BarFooFooClass") {
            guard self.sut.classes.count > 3 else {
              fail("BarFooFooClass not found at expected index")
              return
            }
            let classInfo = self.sut.classes[3]
            expect(classInfo.name) == "BarFooFooClass"
            expect(classInfo.inheritsFromTypes) == []
            expect(classInfo.parentTypeName) == "FooClass.FooFooClass"
          }
        }
      }

      context("visiting a code block with multiple top-level declarations") {
        context("with multiple top-level classes") {
          it("asserts") {
            let content = """
            public class FooClass {}
            public class FooClass {}
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
          // Using a ClassVisitor over a block that has a top-level class
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
          // Using a ClassVisitor over a block that has a top-level enum
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
