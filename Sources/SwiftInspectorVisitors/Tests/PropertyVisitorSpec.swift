// Created by francisco_diaz on 7/7/21.
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
import SwiftInspectorTestHelpers
import Quick
import Nimble

@testable import SwiftInspectorVisitors

final class PropertyVisitorSpec: QuickSpec {
  override func spec() {
    describe("visit(_:)") {
      var sut: PropertyVisitor!

      beforeEach {
        sut = PropertyVisitor()
      }

      context("when there are multiple properties on the same line") {
        let content = """
        public var thing: String, foo: Int
        let red, green, blue: Double
        let seconds: Int, hours, years: Double
        """

        it("detects properties with different types") {
          try sut.walkContent(content)
          let expected: [PropertyInfo] = [
            .init(
              name: "thing",
              typeAnnotation: "String",
              modifiers: [.public, .instance]),
            .init(
              name: "foo",
              typeAnnotation: "Int",
              modifiers: [.public, .instance])
          ]
          expect(sut.properties).to(contain(expected))
        }

        it("detects properties with the same type") {
          try sut.walkContent(content)
          let expected: [PropertyInfo] = [
            .init(
              name: "green",
              typeAnnotation: "Double",
              modifiers: [.internal, .instance]),
            .init(
              name: "red",
              typeAnnotation: "Double",
              modifiers: [.internal, .instance]),
              .init(
                name: "blue",
                typeAnnotation: "Double",
                modifiers: [.internal, .instance])
          ]
          expect(sut.properties).to(contain(expected))
        }

        it("detects properties in a line with both different and equal types") {
          try sut.walkContent(content)
          let expected: [PropertyInfo] = [
            .init(
              name: "seconds",
              typeAnnotation: "Int",
              modifiers: [.internal, .instance]),
            .init(
              name: "hours",
              typeAnnotation: "Double",
              modifiers: [.internal, .instance]),
            .init(
              name: "years",
              typeAnnotation: "Double",
              modifiers: [.internal, .instance])
          ]
          expect(sut.properties).to(contain(expected))
        }
      }

      context("when there is a static property") {
        let content = """
        public static var thing: String = "Hello, World"
        """

        it("detects the property") {
          try sut.walkContent(content)
          expect(sut.properties) == [
            PropertyInfo(
              name: "thing",
              typeAnnotation: "String",
              modifiers: [.public, .static])
          ]
        }
      }

      context("when there is a static property in reverse order") {
        let content = """
        static public var thing: String = "Hello, World"
        """

        it("detects the property") {
          try sut.walkContent(content)
          expect(sut.properties) == [
            PropertyInfo(
              name: "thing",
              typeAnnotation: "String",
              modifiers: [.public, .static])
          ]
        }
      }

      context("when there is a private property") {
        let content = """
        private static var thing: String = "Hello, World"
        """

        it("detects the property") {
          try sut.walkContent(content)
          expect(sut.properties) == [
            PropertyInfo(
              name: "thing",
              typeAnnotation: "String",
              modifiers: [.private, .static])
          ]
        }
      }

      context("when there is a public private(set) property") {
        let content = """
        public private(set) var thing: String = "Hello, World"
        """

        it("detects the property") {
          try sut.walkContent(content)
          expect(sut.properties) == [
            PropertyInfo(
              name: "thing",
              typeAnnotation: "String",
              modifiers: [.public, .privateSet, .instance])
          ]
        }
      }

      context("when there is a public internal(set) property") {
        let content = """
        public internal(set) var thing: String = "Hello, World"
        """

        it("detects the property") {
          try sut.walkContent(content)
          expect(sut.properties) == [
            PropertyInfo(
              name: "thing",
              typeAnnotation: "String",
              modifiers: [.public, .internalSet, .instance])
          ]
        }
      }

      context("when there is a internal public(set) property") {
        let content = """
        internal public(set) var thing: String = "Hello, World"
        """

        it("detects the property") {
          try sut.walkContent(content)
          expect(sut.properties) == [
            PropertyInfo(
              name: "thing",
              typeAnnotation: "String",
              modifiers: [.publicSet, .internal, .instance])
          ]
        }
      }

      context("when there is a fileprivate property") {
        let content = """
        fileprivate static var thing: String = "Hello, World"
        """

        it("detects the property") {
          try sut.walkContent(content)
          expect(sut.properties) == [
            PropertyInfo(
              name: "thing",
              typeAnnotation: "String",
              modifiers: [.fileprivate, .static])
          ]
        }
      }

      context("when there is no type annotation") {
        let content = """
        private static var thing = "Hello, World"
        """

        it("detects the property with no type information") {
          try sut.walkContent(content)
          expect(sut.properties) == [
            PropertyInfo(
              name: "thing",
              typeAnnotation: nil,
              modifiers: [.private, .static])
          ]
        }
      }

      context("when there is a property attribute") {
        let content = """
        @objc public var thing = "Hello, World"
        """

        it("detects the property with no type information") {
          try sut.walkContent(content)
          expect(sut.properties) == [
            PropertyInfo(
              name: "thing",
              typeAnnotation: nil,
              modifiers: [.public, .instance])
          ]
        }
      }

      context("when there is a type declaration in content") {
        let content = """
        let hex: Int
        final class FakeClass {
          let timestamp: Int
        }
        struct FakeStruct {
          let timestamp: Int
        }
        enum FakeEnum {
          var timestamp: Int { 0 }
        }
        protocol FakeProtocol {
          var timestamp: Int { get }
        }
        extension FakeProtocol {
          var timestamp: Int { 0 }
        }
        """

        it("detect properties outside the type declaration") {
          try sut.walkContent(content)
          let expected: [PropertyInfo] = [
            .init(
              name: "hex",
              typeAnnotation: "Int",
              modifiers: [.internal, .instance])
          ]
          expect(sut.properties).to(contain(expected))
        }

        it("does not detect properties within type declaration") {
          try sut.walkContent(content)
          let notExpected: [PropertyInfo] = [
            .init(
              name: "timestamp",
              typeAnnotation: "Int",
              modifiers: [.internal, .instance])
          ]
          expect(sut.properties).notTo(contain(notExpected))
        }
      }

    }
  }
}
