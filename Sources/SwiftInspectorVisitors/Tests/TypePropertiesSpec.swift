// Created by Tyler Hedrick on 8/18/20.
//
// Copyright (c) 2020 Tyler Hedrick
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

@testable import SwiftInspectorAnalyzers

final class TypePropertiesSpec: QuickSpec {
  override func spec() {
    describe("TypeProperties.merge(other:)") {
      let type1 = TypeProperties(
        name: "MyType",
        properties: [
          TypeProperties.PropertyData(
            name: "thing",
            typeAnnotation: "String",
            comment: "",
            modifiers: [.public, .instance])
      ])
      let type2 = TypeProperties(
        name: "MyType",
        properties: [
          TypeProperties.PropertyData(
            name: "foo",
            typeAnnotation: "Int",
            comment: "",
            modifiers: [.public, .instance])
      ])
      let type3 = TypeProperties(
        name: "AnotherType",
        properties: [
          TypeProperties.PropertyData(
            name: "foo",
            typeAnnotation: "Int",
            comment: "",
            modifiers: [.public, .instance])
      ])

      context("when both types have the same name") {
        let result = try? type1.merge(with: type2)
        it("succeeds") {
          expect(result?.name) == "MyType"
        }

        it("has merged props") {
          let set = Set(result?.properties ?? [])
          let expectedSet: Set<TypeProperties.PropertyData> = [
            TypeProperties.PropertyData(
              name: "thing",
              typeAnnotation: "String",
              comment: "",
              modifiers: [.public, .instance]),
            TypeProperties.PropertyData(
              name: "foo",
              typeAnnotation: "Int",
              comment: "",
              modifiers: [.public, .instance])
          ]
          expect(set) == expectedSet
        }
      }

      context("when the types don't match") {
        it("fails to merge and asserts") {
          expect(try type1.merge(with: type3)).to(throwError())
        }
      }

      context("when the other type is nil") {
        it("returns the original") {
          expect(try? type1.merge(with: nil)) == type1
        }
      }
    }
  }
}
