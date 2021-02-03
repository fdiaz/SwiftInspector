// Created by Dan Federman on 1/28/21.
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

final class ProtocolVisitorSpec: QuickSpec {
  private var sut = ProtocolVisitor()

  override func spec() {
    beforeEach {
      self.sut = ProtocolVisitor()
    }

    describe("visit(_:)") {
      context("visiting a single protocol declaration") {
        context("with no conformance") {
          it("finds the type name") {
            let content = """
              public protocol SomeProtocol {}
              """

            try VisitorExecutor.walkVisitor(
              self.sut,
              overContent: content)

            let protocolInfo = self.sut.protocolInfo
            expect(protocolInfo?.name) == "SomeProtocol"
            expect(protocolInfo?.inheritsFromTypes.map { $0.asSource }) == []
            expect(protocolInfo?.genericRequirements) == []
          }
        }

        context("with a single type conformance") {
          it("finds the type name") {
            let content = """
              public protocol SomeProtocol: Equatable {}
              """

            try VisitorExecutor.walkVisitor(
              self.sut,
              overContent: content)

            let protocolInfo = self.sut.protocolInfo
            expect(protocolInfo?.name) == "SomeProtocol"
            expect(protocolInfo?.inheritsFromTypes.map { $0.asSource }) == ["Equatable"]
            expect(protocolInfo?.genericRequirements) == []
          }
        }

        context("with multiple type conformances") {
          it("finds the type name") {
            let content = """
              public protocol SomeProtocol: Foo, Bar {}
              """

            try VisitorExecutor.walkVisitor(
              self.sut,
              overContent: content)

            let protocolInfo = self.sut.protocolInfo
            expect(protocolInfo?.name) == "SomeProtocol"
            expect(protocolInfo?.inheritsFromTypes.map { $0.asSource }) == ["Foo", "Bar"]
            expect(protocolInfo?.genericRequirements) == []
          }
        }

        context("with a single type conformance and generic equals constraint") {
          it("finds both the type conforamnce and generic constraint") {
            let content = """
              public protocol SomeProtocol: Collection where Element == Int {}
              """

            try VisitorExecutor.walkVisitor(
              self.sut,
              overContent: content)

            let protocolInfo = self.sut.protocolInfo
            expect(protocolInfo?.name) == "SomeProtocol"
            expect(protocolInfo?.inheritsFromTypes.map { $0.asSource }) == ["Collection"]
            expect(protocolInfo?.genericRequirements.first?.leftType.asSource) == "Element"
            expect(protocolInfo?.genericRequirements.first?.rightType.asSource) == "Int"
            expect(protocolInfo?.genericRequirements.first?.relationship) == .equals
          }

          context("with a single type conformance and multiple generic constraints") {
            it("finds alll generic constraints") {
              let content = """
              public protocol SomeProtocol: Transformer where
                Input == Int,
                Output: AnyObject
              {}
              """

              try VisitorExecutor.walkVisitor(
                self.sut,
                overContent: content)

              let protocolInfo = self.sut.protocolInfo
              expect(protocolInfo?.name) == "SomeProtocol"
              expect(protocolInfo?.genericRequirements.first?.leftType.asSource) == "Input"
              expect(protocolInfo?.genericRequirements.first?.rightType.asSource) == "Int"
              expect(protocolInfo?.genericRequirements.first?.relationship) == .equals
              expect(protocolInfo?.genericRequirements.last?.leftType.asSource) == "Output"
              expect(protocolInfo?.genericRequirements.last?.rightType.asSource) == "AnyObject"
              expect(protocolInfo?.genericRequirements.last?.relationship) == .conformsTo
            }
          }

          context("with a single type conformance and generic conformance constraint") {
            it("finds both the type conforamnce and generic constraint") {
              let content = """
              public protocol SomeProtocol: Collection where Element: Int {}
              """

              try VisitorExecutor.walkVisitor(
                self.sut,
                overContent: content)

              let protocolInfo = self.sut.protocolInfo
              expect(protocolInfo?.name) == "SomeProtocol"
              expect(protocolInfo?.inheritsFromTypes.map { $0.asSource }) == ["Collection"]
              expect(protocolInfo?.genericRequirements.first?.leftType.asSource) == "Element"
              expect(protocolInfo?.genericRequirements.first?.rightType.asSource) == "Int"
              expect(protocolInfo?.genericRequirements.first?.relationship) == .conformsTo
            }
          }
        }

        context("visiting a code block with multiple top-level declarations") {
          context("with multiple protocols") {
            it("asserts") {
              let content = """
            public protocol FooProtocol {}
            public protocol BarProtocol {}
            """

              // The ProtocolVisitor is only meant to be used over a single protocol.
              // Using a ProtocolVisitor over a block that has multiple top-level
              // protocols is API misuse.
              expect(try VisitorExecutor.walkVisitor(
                      self.sut,
                      overContent: content))
                .to(throwAssertion())
            }
          }

          context("with a top-level class after a protocol") {
            it("asserts") {
              let content = """
            public protocol FooProtocol {}
            public protocol FooClass {}
            """

              // The ProtocolVisitor is only meant to be used over a single protocol.
              // Using a ProtocolVisitor over a block that has a top-level class
              // is API misuse.
              expect(try VisitorExecutor.walkVisitor(
                      self.sut,
                      overContent: content))
                .to(throwAssertion())
            }
          }

          context("with a top-level enum after a protocol") {
            it("asserts") {
              let content = """
            public protocol FooProtocol {}
            public protocol FooEnum {}
            """

              // The ProtocolVisitor is only meant to be used over a single protocol.
              // Using a ProtocolVisitor over a block that has a top-level enum
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

            // The ProtocolVisitor is only meant to be used over a single protocol.
            // Using a ProtocolVisitor over a block that has a top-level class
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

            // The ProtocolVisitor is only meant to be used over a single protocol.
            // Using a ProtocolVisitor over a block that has a top-level class
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

            // The ProtocolVisitor is only meant to be used over a single protocol.
            // Using a ProtocolVisitor over a block that has a top-level enum
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
}
