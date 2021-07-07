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
  override func spec() {

    describe("TypeSyntaxVisitor.merge(_:into:)") {

      context("when there is no existing data about properties") {
        let existingPropertiesInfo: Set<PropertyInfo>? = nil

        context("and the new data is empty") {
          let newPropertiesInfo: Set<PropertyInfo> = []

          it("returns the new data") {
            let result = TypeSyntaxVisitor.merge(
              newPropertiesInfo,
              into: existingPropertiesInfo)
            expect(result).to(equal(newPropertiesInfo))
          }
        }

        context("and the new data describes one or more properties") {
          let newPropertiesInfo: Set<PropertyInfo> = [
            .init(
              name: "thing",
              typeAnnotation: "String",
              comment: "",
              modifiers: [.public, .instance])
          ]

          context("returns the new data") {
            let result = TypeSyntaxVisitor.merge(
              newPropertiesInfo,
              into: existingPropertiesInfo)
            expect(result).to(equal(newPropertiesInfo))
          }
        }
      }

      context("when there is existing data about properties") {
        let existingPropertiesInfo: Set<PropertyInfo> = [
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

        it("merges the existing data with new data") {
          let newPropertiesInfo: Set<PropertyInfo> = [
            .init(
              name: "thing",
              typeAnnotation: "String",
              comment: "",
              modifiers: [.public, .instance])
          ]

          let result = TypeSyntaxVisitor.merge(
            newPropertiesInfo,
            into: existingPropertiesInfo)

          expect(result).to(equal(existingPropertiesInfo.union(newPropertiesInfo)))
        }
      }
    }

    describe("visit(_:)") {
      var sut: TypeSyntaxVisitor!

      beforeEach {
        sut = TypeSyntaxVisitor(typeName: "FakeType")
      }

      context("when there are no properties") {
        let content = """
                      public final class FakeType {}
                      """

        it("returns empty property list") {
          try VisitorExecutor.walkVisitor(sut, overContent: content)
          expect(sut.propertiesInfo).to(beEmpty())
        }
      }

      context("when there is a property") {
        let content = """
        public final class FakeType {
          public var thing: String = "Hello, World"
        }
        """

        it("returns nil if the type name is not present") {
          let sut = TypeSyntaxVisitor(typeName: "AnotherType")
          try VisitorExecutor.walkVisitor(sut, overContent: content)
          expect(sut.propertiesInfo).to(beNil())
        }

        it("detects the properties") {
          try VisitorExecutor.walkVisitor(sut, overContent: content)
          expect(sut.propertiesInfo) == [
            PropertyInfo(
              name: "thing",
              typeAnnotation: "String",
              comment: "",
              modifiers: [.public, .instance])
          ]
        }
      }

      context("when there is a property in a nested type with the same type name") {
        let content = """
        public final class FakeType {
          public var thing: String = "Hello, World"

          enum FakeType {
            static let foo: String = "Hola"
          }
        }
        """

        /*
         This is actually not the ideal result of this and is a limitation of the implementation
         Ideally you would have to pass in `FakeType.FakeType` to get this nested type's property
         information. For now we are accepting this limitation and have this test to showcase
         what happens in this scenario.
         */
        it("detects and merges the properties") {
          try VisitorExecutor.walkVisitor(sut, overContent: content)
          let expectedPropSet: Set<PropertyInfo> = [
            .init(
              name: "thing",
              typeAnnotation: "String",
              comment: "",
              modifiers: [.public, .instance]),
            .init(
              name: "foo",
              typeAnnotation: "String",
              comment: "",
              modifiers: [.internal, .static])
          ]
          expect(sut.propertiesInfo) == expectedPropSet
        }
      }

      context("when there is a property (struct)") {
        let content = """
        public struct FakeType {
          public var thing: String = "Hello, World"
        }
        """

        it("detects the properties") {
          try VisitorExecutor.walkVisitor(sut, overContent: content)
          expect(sut.propertiesInfo) == [
            PropertyInfo(
              name: "thing",
              typeAnnotation: "String",
              comment: "",
              modifiers: [.public, .instance])
          ]
        }
      }

      context("when there is a property (enum)") {
        let content = """
        public enum FakeType {
          public var thing: String = "Hello, World"
        }
        """

        it("detects the properties") {
          try VisitorExecutor.walkVisitor(sut, overContent: content)
          expect(sut.propertiesInfo) == [
            PropertyInfo(
              name: "thing",
              typeAnnotation: "String",
              comment: "",
              modifiers: [.public, .instance])
          ]
        }
      }

      context("when there is a property (protocol)") {
        let content = """
        public protocol FakeType {
          var thing: String { get }
        }
        """

        it("detects the properties") {
          try VisitorExecutor.walkVisitor(sut, overContent: content)
          expect(sut.propertiesInfo) == [
            PropertyInfo(
              name: "thing",
              typeAnnotation: "String",
              comment: "",
              modifiers: [.internal, .instance])
          ]
        }
      }

      context("when there is a property (extension)") {

        context("following the type declaration") {

          context("and the type declaration has no properties") {
            let content = """
            public class FakeType { }

            extension FakeType {
              var thing: String = "Hello, World"
            }
            """

            it("detects the property in the extension") {
              try VisitorExecutor.walkVisitor(sut, overContent: content)
              expect(sut.propertiesInfo) == [
                PropertyInfo(
                  name: "thing",
                  typeAnnotation: "String",
                  comment: "",
                  modifiers: [.internal, .instance])
              ]
            }
          }

          context("and the type declaration has properties") {
            let content = """
            public class FakeType {
              var thing: String = "Hello, World"
            }

            extension FakeType {
              var anotherThing: String = "Goodbye, World"
            }
            """

            it("detects properties in the declaration and extension") {
              try VisitorExecutor.walkVisitor(sut, overContent: content)
              expect(sut.propertiesInfo) == [
                PropertyInfo(
                  name: "thing",
                  typeAnnotation: "String",
                  comment: "",
                  modifiers: [.internal, .instance]),
                PropertyInfo(
                  name: "anotherThing",
                  typeAnnotation: "String",
                  comment: "",
                  modifiers: [.internal, .instance])
              ]
            }
          }
        }

        context("and no type declaration") {
          let content = """
          extension FakeType {
            var thing: String = "Hello, World"
          }
          """

          it("detects the property in the extension") {
            try VisitorExecutor.walkVisitor(sut, overContent: content)
            expect(sut.propertiesInfo) == [
              PropertyInfo(
                name: "thing",
                typeAnnotation: "String",
                comment: "",
                modifiers: [.internal, .instance])
            ]
          }
        }
      }

      context("when there are multiple properties") {
        let content = """
        public final class FakeType {
          public var thing: String = "Hello, World"
          var foo: Int = 4
        }
        """

        it("detects the properties") {
          try VisitorExecutor.walkVisitor(sut, overContent: content)
          let expectedPropSet: Set<PropertyInfo> = [
            .init(
              name: "thing",
              typeAnnotation: "String",
              comment: "",
              modifiers: [.public, .instance]),
            .init(
              name: "foo",
              typeAnnotation: "Int",
              comment: "",
              modifiers: [.internal, .instance])
          ]
          expect(sut.propertiesInfo) == expectedPropSet
        }
      }

    }
  }
}
