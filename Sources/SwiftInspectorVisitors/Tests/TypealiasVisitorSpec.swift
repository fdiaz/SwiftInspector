// Created by Dan Federman on 2/17/21.
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

import Nimble
import Quick
import SwiftInspectorTestHelpers

@testable import SwiftInspectorVisitors

final class TypealiasVisitorSpec: QuickSpec {
  private var sut = TypealiasVisitor()

  override func spec() {
    beforeEach {
      self.sut = TypealiasVisitor()
    }

    describe("visit(_:)") {
      context("visiting a typealias") {
        var associatedTypeNameToInfoMap: [String: TypealiasInfo]?
        beforeEach {
          let content = """
            public typealias CountableClosedRange<Bound> = ClosedRange<Bound> where Bound : Strideable, Bound.Stride : SignedInteger
            """

          try? self.sut.walkContent(content)

          associatedTypeNameToInfoMap = self.sut.typealiases
            .reduce(into: [String: TypealiasInfo]()) { (result, typealiasInfo) in
              result[typealiasInfo.name] = typealiasInfo
            }
        }

        it("finds the typealias CountableClosedRange") {
          expect(associatedTypeNameToInfoMap?["CountableClosedRange"]).toNot(beNil())
        }

        it("finds the typealias CountableClosedRange's generic parameters") {
          expect(associatedTypeNameToInfoMap?["CountableClosedRange"]?.genericParameters.count) == 1
          expect(associatedTypeNameToInfoMap?["CountableClosedRange"]?.genericParameters.first?.name) == "Bound"
        }

        it("finds the typealias CountableClosedRange's generic requirements") {
          expect(associatedTypeNameToInfoMap?["CountableClosedRange"]?.genericRequirements.count) == 2

          expect(associatedTypeNameToInfoMap?["CountableClosedRange"]?.genericRequirements.first?.leftType.asSource) == "Bound"
          expect(associatedTypeNameToInfoMap?["CountableClosedRange"]?.genericRequirements.first?.relationship) == .conformsTo
          expect(associatedTypeNameToInfoMap?["CountableClosedRange"]?.genericRequirements.first?.rightType.asSource) == "Strideable"

          expect(associatedTypeNameToInfoMap?["CountableClosedRange"]?.genericRequirements.last?.leftType.asSource) == "Bound.Stride"
          expect(associatedTypeNameToInfoMap?["CountableClosedRange"]?.genericRequirements.last?.relationship) == .conformsTo
          expect(associatedTypeNameToInfoMap?["CountableClosedRange"]?.genericRequirements.last?.rightType.asSource) == "SignedInteger"
        }

        it("finds the typealias CountableClosedRange's modifiers") {
          expect(associatedTypeNameToInfoMap?["CountableClosedRange"]?.modifiers) == [.public]
        }
      }
    }
  }
}
