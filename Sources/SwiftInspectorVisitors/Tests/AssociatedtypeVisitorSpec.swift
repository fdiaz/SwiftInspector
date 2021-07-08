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

final class AssociatedtypeVisitorSpec: QuickSpec {
  private var sut = AssociatedtypeVisitor()

  override func spec() {
    beforeEach {
      self.sut = AssociatedtypeVisitor()
    }

    describe("visit(_:)") {
      context("visiting a protocol with associated types") {
        var associatedTypeNameToInfoMap: [String: AssociatedtypeInfo]?
        beforeEach {
          let content = """
            public protocol Collection {
              associatedtype Element

              associatedtype Index : Comparable where Self.Index == Self.Indices.Element

              associatedtype Iterator = IndexingIterator<Self>

              associatedtype SubSequence : Collection = Slice<Self> where Self.Element == Self.SubSequence.Element, Self.SubSequence == Self.SubSequence.SubSequence

              associatedtype Indices : Collection = DefaultIndices<Self> where Self.Indices == Self.Indices.SubSequence
            }
            """

          try? self.sut.walkContent(content)

          associatedTypeNameToInfoMap = self.sut.associatedTypes
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
  }
}
