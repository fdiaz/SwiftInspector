// Created by Michael Bachand on 4/8/21.
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
import Foundation
import SwiftInspectorTestHelpers

@testable import SwiftInspectorVisitors

final class TypeSyntaxVisitorSpec: QuickSpec {
  private var sut: TypeSyntaxVisitor!

  override func spec() {

    describe("TypeSyntaxVisitor.merge(_:into:)") {

      context("when there is no existing data about properties") {

        context("and the new data is empty") {
          it("returns the new data") {
            let result = TypeSyntaxVisitor.merge([], into: nil)
            expect(result).to(equal([]))
          }
        }

        context("and the new data describes one or more properties") {
          context("returns the new data") {
            let newPropertyData = PropertyData(
              name: "thing",
              typeAnnotation: "String",
              comment: "",
              modifiers: [.public, .instance])

            let result = TypeSyntaxVisitor.merge([newPropertyData], into: nil)
            expect(result).to(equal([newPropertyData]))
          }
        }
      }

      context("when there is existing data about properties") {

        it("merges the existing and new data") {
          let newPropertyData = PropertyData(
            name: "thing",
            typeAnnotation: "String",
            comment: "",
            modifiers: [.public, .instance])
          let existingPropertiesData: Set<PropertyData> = [
            .init(
              name: "foo",
              typeAnnotation: "Int",
              comment: "",
              modifiers: [.public, .instance]),
            .init(
              name: "bar",
              typeAnnotation: "String",
              comment: "",
              modifiers: [.fileprivate])
          ]

          let result = TypeSyntaxVisitor.merge(
            [newPropertyData],
            into: existingPropertiesData)

          expect(result.count).to(equal(3))
          expect(result.contains(newPropertyData)).to(beTrue())
          expect(result.isSuperset(of: existingPropertiesData)).to(beTrue())
        }
      }
    }
  }
}
