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
  private var fileURL: URL!
  private var sut = GenericRequirementVisitor()

  override func spec() {
    beforeEach {
      self.sut = GenericRequirementVisitor()
    }
    afterEach {
      guard let fileURL = self.fileURL else {
        return
      }
      try? Temporary.removeItem(at: fileURL)
    }

    describe("visiting a syntax tree involving a protocol") {
      context("that has no generic constraints") {
        it("finds no generic requirements") {
          let content = """
            public protocol SomeGenericProtocol: GenericProtocol {}
            """

          self.fileURL = try VisitorExecutor.createFile(
            withContent: content,
            andWalk: self.sut)

          expect(self.sut.genericRequirements.first).to(beNil())
        }
      }

      context("that has one generic constraint") {
        it("finds the generic requirements") {
          let content = """
            public protocol SomeGenericProtocol: GenericProtocol where
              LeftType == RightType
            {}
            """

          self.fileURL = try VisitorExecutor.createFile(
            withContent: content,
            andWalk: self.sut)

          expect(self.sut.genericRequirements.first) == GenericRequirement(
            leftType: "LeftType",
            rightType: "RightType",
            relationship: .equals)
        }
      }

      context("that has two generic constraints") {
        it("finds both requirements") {
          let content = """
            public protocol SomeGenericProtocol: GenericProtocol where
              LeftType1 == RightType1,
              LeftType2: RightType2
            {}
            """

          self.fileURL = try VisitorExecutor.createFile(
            withContent: content,
            andWalk: self.sut)

          expect(self.sut.genericRequirements.first) == GenericRequirement(
            leftType: "LeftType1",
            rightType: "RightType1",
            relationship: .equals)
          expect(self.sut.genericRequirements.last) == GenericRequirement(
            leftType: "LeftType2",
            rightType: "RightType2",
            relationship: .conformsTo)
        }
      }
    }

    describe("visiting a syntax tree involving an extension") {
      context("that has no generic constraints") {
        it("finds no generic requirements") {
          let content = """
            extension Array {}
            """

          self.fileURL = try VisitorExecutor.createFile(
            withContent: content,
            andWalk: self.sut)

          expect(self.sut.genericRequirements.first).to(beNil())
        }
      }

      context("that has one generic constraint") {
        it("finds the generic requirements") {
          let content = """
            extension Array where
              Element: AnyObject
            {}
            """

          self.fileURL = try VisitorExecutor.createFile(
            withContent: content,
            andWalk: self.sut)

          expect(self.sut.genericRequirements.first) == GenericRequirement(
            leftType: "Element",
            rightType: "AnyObject",
            relationship: .conformsTo)
        }
      }

      context("that has two generic constraints") {
        it("finds both requirements") {
          let content = """
            extension Dictionary where
              Key: AnyObject,
              Value == CustomStringConvertible
            {}
            """

          self.fileURL = try VisitorExecutor.createFile(
            withContent: content,
            andWalk: self.sut)

          expect(self.sut.genericRequirements.first) == GenericRequirement(
            leftType: "Key",
            rightType: "AnyObject",
            relationship: .conformsTo)
          expect(self.sut.genericRequirements.last) == GenericRequirement(
            leftType: "Value",
            rightType: "CustomStringConvertible",
            relationship: .equals)
        }
      }
    }

    describe("visiting a syntax tree involving an associatedtype") {
      context("that has no generic constraints") {
        it("finds no generic requirements") {
          let content = """
            public protocol Test {
              associatedtype SomeType: SomeProtocol
            }
            """

          self.fileURL = try VisitorExecutor.createFile(
            withContent: content,
            andWalk: self.sut)

          expect(self.sut.genericRequirements.first).to(beNil())
        }
      }

      context("that has one generic constraint") {
        it("finds the generic requirements") {
          let content = """
            public protocol Test {
              associatedtype SomeType: SomeProtocol where
                Element: AnyObject
            }
            """

          self.fileURL = try VisitorExecutor.createFile(
            withContent: content,
            andWalk: self.sut)

          expect(self.sut.genericRequirements.first) == GenericRequirement(
            leftType: "Element",
            rightType: "AnyObject",
            relationship: .conformsTo)
        }
      }

      context("that has two generic constraints") {
        it("finds both requirements") {
          let content = """
            public protocol Test {
              associatedtype SomeType: SomeProtocol where
                Key: AnyObject,
                Value == CustomStringConvertible
            }
            """

          self.fileURL = try VisitorExecutor.createFile(
            withContent: content,
            andWalk: self.sut)

          expect(self.sut.genericRequirements.first) == GenericRequirement(
            leftType: "Key",
            rightType: "AnyObject",
            relationship: .conformsTo)
          expect(self.sut.genericRequirements.last) == GenericRequirement(
            leftType: "Value",
            rightType: "CustomStringConvertible",
            relationship: .equals)
        }
      }

      describe("visiting a syntax tree involving a contextual where clause") {
        context("that has one generic constraint") {
          it("finds the generic requirements") {
            let content = """
              extension Array
              {
                func print() where Element: CustomStringConvertible {
                  forEach { print($0) }
                }
              }
              """

            self.fileURL = try VisitorExecutor.createFile(
              withContent: content,
              andWalk: self.sut)

            expect(self.sut.genericRequirements.first) == GenericRequirement(
              leftType: "Element",
              rightType: "CustomStringConvertible",
              relationship: .conformsTo)
          }
        }
      }
    }
  }
}
