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
      context("visiting a single, simple protocol declaration") {
        context("with no conformance") {
          beforeEach {
            let content = """
              public protocol SomeProtocol {}
              """

            try? VisitorExecutor.walkVisitor(
              self.sut,
              overContent: content)
          }
          it("finds the type name") {
            expect(self.sut.protocolInfo?.name) == "SomeProtocol"
          }

          it("finds no inheritance") {
            expect(self.sut.protocolInfo?.inheritsFromTypes.map { $0.asSource }) == []
          }

          it("finds no generic requirements") {
            expect(self.sut.protocolInfo?.genericRequirements) == []
          }

          it("finds the modifiers") {
            expect(self.sut.protocolInfo?.modifiers) == .init(["public"])
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

          context("with associatedtypes") {
            var associatedTypeNameToInfoMap: [String: AssociatedtypeInfo]?
            beforeEach {
              let content = """
                public protocol Collection {
                  typealias IndexDistance = Int

                  associatedtype Element

                  associatedtype Index : Comparable where Self.Index == Self.Indices.Element

                  associatedtype Iterator = IndexingIterator<Self>

                  associatedtype SubSequence : Collection = Slice<Self> where Self.Element == Self.SubSequence.Element, Self.SubSequence == Self.SubSequence.SubSequence

                  associatedtype Indices : Collection = DefaultIndices<Self> where Self.Indices == Self.Indices.SubSequence
                }
                """

              try? VisitorExecutor.walkVisitor(
                self.sut,
                overContent: content)

              associatedTypeNameToInfoMap = self.sut.protocolInfo?.associatedTypes
                .reduce(into: [String: AssociatedtypeInfo]()) { (result, associatedTypeInfo) in
                  result[associatedTypeInfo.name] = associatedTypeInfo
                }
            }

            it("finds the associatedtype Element") {
              expect(associatedTypeNameToInfoMap?["Element"]).toNot(beNil())
            }

            it("finds the associatedtype Index") {
              expect(associatedTypeNameToInfoMap?["Index"]).toNot(beNil())
            }

            it("finds the associatedtype Index's inheritance") {
              expect(associatedTypeNameToInfoMap?["Index"]?.inheritsFromTypes.count) == 1
              expect(associatedTypeNameToInfoMap?["Index"]?.inheritsFromTypes.first?.asSource) == "Comparable"
            }

            it("finds the associatedtype Index's generic requirements") {
              expect(associatedTypeNameToInfoMap?["Index"]?.genericRequirements.count) == 1
              expect(associatedTypeNameToInfoMap?["Index"]?.genericRequirements.first?.leftType.asSource) == "Self.Index"
              expect(associatedTypeNameToInfoMap?["Index"]?.genericRequirements.first?.rightType.asSource) == "Self.Indices.Element"
            }

            it("finds the associatedtype Iterator") {
              expect(associatedTypeNameToInfoMap?["Iterator"]).toNot(beNil())
            }

            it("finds the associatedtype Iterator's initializer") {
              expect(associatedTypeNameToInfoMap?["Iterator"]?.initializer?.asSource) == "IndexingIterator<Self>"
            }

            it("finds the associatedtype SubSequence") {
              expect(associatedTypeNameToInfoMap?["SubSequence"]).toNot(beNil())
            }

            it("finds the associatedtype SubSequence's inheritance") {
              expect(associatedTypeNameToInfoMap?["SubSequence"]?.inheritsFromTypes.count) == 1
              expect(associatedTypeNameToInfoMap?["SubSequence"]?.inheritsFromTypes.first?.asSource) == "Collection"
            }

            it("finds the associatedtype SubSequence's generic requirements") {
              expect(associatedTypeNameToInfoMap?["SubSequence"]?.genericRequirements.count) == 2
              expect(associatedTypeNameToInfoMap?["SubSequence"]?.genericRequirements.first?.leftType.asSource) == "Self.Element"
              expect(associatedTypeNameToInfoMap?["SubSequence"]?.genericRequirements.first?.relationship) == .equals
              expect(associatedTypeNameToInfoMap?["SubSequence"]?.genericRequirements.first?.rightType.asSource) == "Self.SubSequence.Element"
              expect(associatedTypeNameToInfoMap?["SubSequence"]?.genericRequirements.last?.leftType.asSource) == "Self.SubSequence"
              expect(associatedTypeNameToInfoMap?["SubSequence"]?.genericRequirements.last?.relationship) == .equals
              expect(associatedTypeNameToInfoMap?["SubSequence"]?.genericRequirements.last?.rightType.asSource) == "Self.SubSequence.SubSequence"
            }

            it("finds the associatedtype Indices") {
              expect(associatedTypeNameToInfoMap?["Indices"]).toNot(beNil())
            }

            it("finds the associatedtype Indices's inheritance") {
              expect(associatedTypeNameToInfoMap?["Indices"]?.inheritsFromTypes.count) == 1
              expect(associatedTypeNameToInfoMap?["Indices"]?.inheritsFromTypes.first?.asSource) == "Collection"
            }

            it("finds the associatedtype Indices's inheritance") {
              expect(associatedTypeNameToInfoMap?["Indices"]?.inheritsFromTypes.count) == 1
              expect(associatedTypeNameToInfoMap?["Indices"]?.initializer?.asSource) == "DefaultIndices<Self>"
            }

            it("finds the associatedtype Indices's generic requirement") {
              expect(associatedTypeNameToInfoMap?["Indices"]?.genericRequirements.count) == 1
              expect(associatedTypeNameToInfoMap?["Indices"]?.genericRequirements.first?.leftType.asSource) == "Self.Indices"
              expect(associatedTypeNameToInfoMap?["Indices"]?.genericRequirements.first?.relationship) == .equals
              expect(associatedTypeNameToInfoMap?["Indices"]?.genericRequirements.first?.rightType.asSource) == "Self.Indices.SubSequence"
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
