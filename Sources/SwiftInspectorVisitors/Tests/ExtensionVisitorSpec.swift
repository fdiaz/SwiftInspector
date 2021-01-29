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

final class ExtensionVisitorSpec: QuickSpec {
  private var sut = ExtensionVisitor()

  override func spec() {
    beforeEach {
      self.sut = ExtensionVisitor()
    }

    describe("visit(_:)") {
      context("visiting a single extension declaration") {
        context("with no conformance") {
          it("finds the type name") {
            let content = """
              public extension Array {}
              """

            try VisitorExecutor.walkVisitor(
              self.sut,
              overContent: content)

            let extensionInfo = self.sut.extensionInfo
            expect(extensionInfo?.name) == "Array"
            expect(extensionInfo?.inheritsFromTypes) == []
          }
        }

        context("with a single type conformance") {
          it("finds the type name") {
            let content = """
              public extension Array: Foo {}
              """

            try VisitorExecutor.walkVisitor(
              self.sut,
              overContent: content)

            let extensionInfo = self.sut.extensionInfo
            expect(extensionInfo?.name) == "Array"
            expect(extensionInfo?.inheritsFromTypes) == ["Foo"]
          }
        }

        context("with multiple type conformances") {
          it("finds the inheritance types") {
            let content = """
              public extension Array: Foo, Bar {}
              """

            try VisitorExecutor.walkVisitor(
              self.sut,
              overContent: content)

            let extensionInfo = self.sut.extensionInfo
            expect(extensionInfo?.name) == "Array"
            expect(extensionInfo?.inheritsFromTypes) == ["Foo", "Bar"]
          }
        }
      }

      context("visiting a code block with nested declarations") {
        context("visiting a class with nested types") {
          beforeEach {
            let content = """
              public extension Array {
                struct TestStruct {
                  struct InnerStruct {}
                  // TODO: find this definition
                  class InnerClass {}
                  // TODO: find this definition
                  enum InnerEnum {}
                }

                // TODO: find this definition and inner definitions
                class TestClass {
                  struct InnerStruct {}
                  class InnerClass {}
                  enum InnerEnum {}
                }

                // TODO: find this definition and inner definitions
                enum TestEnum {
                  struct InnerStruct {}
                  class InnerClass {}
                  enum InnerEnum {}
                }
              }
              """

            try? VisitorExecutor.walkVisitor(
              self.sut,
              overContent: content)
          }

          it("finds extension") {
            expect(self.sut.extensionInfo?.name) == "Array"
          }

          it("finds TestStruct") {
            let matchingStructs = self.sut.structs.filter {
              $0.name == "TestStruct"
                && $0.parentTypeName == "Array"
            }
            expect(matchingStructs.count) == 1
          }

          it("finds TestStruct.InnerStruct") {
            let matchingStructs = self.sut.structs.filter {
              $0.name == "InnerStruct"
                && $0.parentTypeName == "Array.TestStruct"
            }
            expect(matchingStructs.count) == 1
          }
        }
      }

      context("visiting a code block with multiple top-level declarations") {
        context("with multiple top-level classes") {
          it("asserts") {
            let content = """
            public extension Array {}
            public extension Dictionary {}
            """

            // The ExtensionVisitor is only meant to be used over a single extension.
            // Using a ExtensionVisitor over a block that has multiple top-level
            // extension is API misuse.
            expect(try VisitorExecutor.walkVisitor(
                    self.sut,
                    overContent: content))
              .to(throwAssertion())
          }
        }

        context("with a top-level struct after an extension") {
          it("asserts") {
            let content = """
            public extension Array {}
            public struct FooStruct {}
            """

            // The ExtensionVisitor is only meant to be used over a single extension.
            // Using a ExtensionVisitor over a block that has a top-level struct
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
            public extension Array {}
            public struct FooEnum {}
            """

            // The ExtensionVisitor is only meant to be used over a single extension.
            // Using a ExtensionVisitor over a block that has a top-level enum
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

          // The ExtensionVisitor is only meant to be used over a single extension.
          // Using a ExtensionVisitor over a block that has a top-level class
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

          // The ExtensionVisitor is only meant to be used over a single extension.
          // Using a ExtensionVisitor over a block that has a top-level class
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

          // The ExtensionVisitor is only meant to be used over a single extension.
          // Using a ExtensionVisitor over a block that has a top-level enum
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

          // The ExtensionVisitor is only meant to be used over a single extension.
          // Using a ExtensionVisitor over a block that has a top-level enum
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
