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

final class GenericRequirementVisitorSpec: QuickSpec {
  private var sut = GenericRequirementVisitor()

  override func spec() {
    beforeEach {
      self.sut = GenericRequirementVisitor()
    }

    describe("visit(_:)") {
      context("visiting a syntax tree involving a protocol that has no generic constraints") {
        it("finds no generic requirements") {
          let content = """
            public protocol SomeGenericProtocol: GenericProtocol {}
            """

          try VisitorExecutor.walkVisitor(
            self.sut,
            overContent: content)

          expect(self.sut.genericRequirements).to(beEmpty())
        }
      }

      context("visiting a syntax tree involving a protocol that has one generic constraint") {
        it("finds the generic requirements") {
          let content = """
            public protocol SomeGenericProtocol: GenericProtocol where
              LeftType == RightType
            {}
            """

          try VisitorExecutor.walkVisitor(
            self.sut,
            overContent: content)

          expect(self.sut.genericRequirements.first) == GenericRequirement(
            leftType: "LeftType",
            rightType: "RightType",
            relationship: .equals)
        }
      }

      context("visiting a syntax tree involving a protocol that has two generic constraints") {
        beforeEach {
          let content = """
            public protocol SomeGenericProtocol: GenericProtocol where
              LeftType1 == RightType1,
              LeftType2: RightType2
            {}
            """

          try? VisitorExecutor.walkVisitor(
            self.sut,
            overContent: content)
        }

        it("finds the first requirement") {
          expect(self.sut.genericRequirements.first) == GenericRequirement(
            leftType: "LeftType1",
            rightType: "RightType1",
            relationship: .equals)
        }

        it("finds the second requirement") {
          expect(self.sut.genericRequirements.last) == GenericRequirement(
            leftType: "LeftType2",
            rightType: "RightType2",
            relationship: .conformsTo)
        }
      }

      context("visiting a syntax tree involving an extension that has no generic constraints") {
        it("finds no generic requirements") {
          let content = """
            extension Array {}
            """

          try VisitorExecutor.walkVisitor(
            self.sut,
            overContent: content)

          expect(self.sut.genericRequirements.first).to(beNil())
        }
      }

      context("visiting a syntax tree involving an extension that has one generic constraint") {
        it("finds the generic requirements") {
          let content = """
            extension Array where
              Element: AnyObject
            {}
            """

          try VisitorExecutor.walkVisitor(
            self.sut,
            overContent: content)

          expect(self.sut.genericRequirements.first) == GenericRequirement(
            leftType: "Element",
            rightType: "AnyObject",
            relationship: .conformsTo)
        }
      }

      context("visiting a syntax tree involving an extension that has two generic constraints") {
        beforeEach {
          let content = """
            extension Dictionary where
              Key: AnyObject,
              Value == CustomStringConvertible
            {}
            """

          try? VisitorExecutor.walkVisitor(
            self.sut,
            overContent: content)
        }
        it("finds the first requirement") {
          expect(self.sut.genericRequirements.first) == GenericRequirement(
            leftType: "Key",
            rightType: "AnyObject",
            relationship: .conformsTo)
        }

        it("finds the second requirement") {
          expect(self.sut.genericRequirements.last) == GenericRequirement(
            leftType: "Value",
            rightType: "CustomStringConvertible",
            relationship: .equals)
        }
      }

      context("visiting a syntax tree involving an associatedtype that has no generic constraints") {
        it("finds no generic requirements") {
          let content = """
            public protocol Test {
              associatedtype SomeType: SomeProtocol
            }
            """

          try VisitorExecutor.walkVisitor(
            self.sut,
            overContent: content)

          expect(self.sut.genericRequirements.first).to(beNil())
        }
      }

      context("visiting a syntax tree involving an associatedtype that has one generic constraint") {
        it("finds the generic requirements") {
          let content = """
            associatedtype SomeType: SomeProtocol where
              Element: AnyObject
            """

          try VisitorExecutor.walkVisitor(
            self.sut,
            overContent: content)

          expect(self.sut.genericRequirements.first) == GenericRequirement(
            leftType: "Element",
            rightType: "AnyObject",
            relationship: .conformsTo)
        }
      }

      context("visiting a syntax tree involving an associatedtype that has two generic constraints") {
        beforeEach {
          let content = """
            associatedtype SomeType: SomeProtocol where
              Key: AnyObject,
              Value == CustomStringConvertible
            """

          try? VisitorExecutor.walkVisitor(
            self.sut,
            overContent: content)
        }

        it("finds the first requirement") {
          expect(self.sut.genericRequirements.first) == GenericRequirement(
            leftType: "Key",
            rightType: "AnyObject",
            relationship: .conformsTo)
        }

        it("finds the second requirement") {
          expect(self.sut.genericRequirements.last) == GenericRequirement(
            leftType: "Value",
            rightType: "CustomStringConvertible",
            relationship: .equals)
        }
      }

      context("visiting a syntax tree involving a contextual where clause that has one generic constraint") {
        it("finds the generic requirements") {
          let content = """
              func print() where Element: CustomStringConvertible {
                forEach { print($0) }
              }
              """

          try VisitorExecutor.walkVisitor(
            self.sut,
            overContent: content)

          expect(self.sut.genericRequirements.first) == GenericRequirement(
            leftType: "Element",
            rightType: "CustomStringConvertible",
            relationship: .conformsTo)
        }
      }
    }
  }
}
