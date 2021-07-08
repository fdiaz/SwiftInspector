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

final class PropertySyntaxVisitorSpec: QuickSpec {
  override func spec() {
    describe("visit(_:)") {
      var sut: PropertySyntaxVisitor!

      beforeEach {
        sut = PropertySyntaxVisitor()
      }

      context("when there are multiple properties on the same line") {
        let content = """
        public final class FakeType {
          public var thing: String, foo: Int
        }
        """

        it("detects the properties") {
          try sut.walkContent(content)
          let expectedPropSet: Set<PropertyInfo> = [
            .init(
              name: "thing",
              typeAnnotation: "String",
              modifiers: [.public, .instance]),
            .init(
              name: "foo",
              typeAnnotation: "Int",
              modifiers: [.public, .instance])
          ]
          expect(sut.propertiesInfo) == expectedPropSet
        }
      }

      context("when there is a static property") {
        let content = """
        public final class FakeType {
          public static var thing: String = "Hello, World"
        }
        """

        it("detects the property") {
          try sut.walkContent(content)
          expect(sut.propertiesInfo) == [
            PropertyInfo(
              name: "thing",
              typeAnnotation: "String",
              modifiers: [.public, .static])
          ]
        }
      }

      context("when there is a static property in reverse order") {
        let content = """
        public final class FakeType {
          static public var thing: String = "Hello, World"
        }
        """

        it("detects the property") {
          try sut.walkContent(content)
          expect(sut.propertiesInfo) == [
            PropertyInfo(
              name: "thing",
              typeAnnotation: "String",
              modifiers: [.public, .static])
          ]
        }
      }

      context("when there is a private property") {
        let content = """
        public final class FakeType {
          private static var thing: String = "Hello, World"
        }
        """

        it("detects the property") {
          try sut.walkContent(content)
          expect(sut.propertiesInfo) == [
            PropertyInfo(
              name: "thing",
              typeAnnotation: "String",
              modifiers: [.private, .static])
          ]
        }
      }

      context("when there is a public private(set) property") {
        let content = """
        public final class FakeType {
          public private(set) var thing: String = "Hello, World"
        }
        """

        it("detects the property") {
          try sut.walkContent(content)
          expect(sut.propertiesInfo) == [
            PropertyInfo(
              name: "thing",
              typeAnnotation: "String",
              modifiers: [.public, .privateSet, .instance])
          ]
        }
      }

      context("when there is a public internal(set) property") {
        let content = """
        public final class FakeType {
          public internal(set) var thing: String = "Hello, World"
        }
        """

        it("detects the property") {
          try sut.walkContent(content)
          expect(sut.propertiesInfo) == [
            PropertyInfo(
              name: "thing",
              typeAnnotation: "String",
              modifiers: [.public, .internalSet, .instance])
          ]
        }
      }

      context("when there is a internal public(set) property") {
        let content = """
        public final class FakeType {
          internal public(set) var thing: String = "Hello, World"
        }
        """

        it("detects the property") {
          try sut.walkContent(content)
          expect(sut.propertiesInfo) == [
            PropertyInfo(
              name: "thing",
              typeAnnotation: "String",
              modifiers: [.publicSet, .internal, .instance])
          ]
        }
      }

      context("when there is a fileprivate property") {
        let content = """
        public final class FakeType {
          fileprivate static var thing: String = "Hello, World"
        }
        """

        it("detects the property") {
          try sut.walkContent(content)
          expect(sut.propertiesInfo) == [
            PropertyInfo(
              name: "thing",
              typeAnnotation: "String",
              modifiers: [.fileprivate, .static])
          ]
        }
      }

      context("when there is no type annotation") {
        let content = """
        public final class FakeType {
          private static var thing = "Hello, World"
        }
        """

        it("detects the property with no type information") {
          try sut.walkContent(content)
          expect(sut.propertiesInfo) == [
            PropertyInfo(
              name: "thing",
              typeAnnotation: nil,
              modifiers: [.private, .static])
          ]
        }
      }

      context("when there is a property attribute") {
        let content = """
        public final class FakeType {
          @objc public var thing = "Hello, World"
        }
        """

        it("detects the property with no type information") {
          try sut.walkContent(content)
          expect(sut.propertiesInfo) == [
            PropertyInfo(
              name: "thing",
              typeAnnotation: nil,
              modifiers: [.public, .instance])
          ]
        }
      }

    }
  }
}
