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
        let existingPropertiesData: Set<PropertyData>? = nil

        context("and the new data is empty") {
          let newPropertiesData: Set<PropertyData> = []

          it("returns the new data") {
            let result = TypeSyntaxVisitor.merge(
              newPropertiesData,
              into: existingPropertiesData)
            expect(result).to(equal(newPropertiesData))
          }
        }

        context("and the new data describes one or more properties") {
          let newPropertiesData: Set<PropertyData> = [
            .init(
              name: "thing",
              typeAnnotation: "String",
              comment: "",
              modifiers: [.public, .instance])
          ]

          context("returns the new data") {
            let result = TypeSyntaxVisitor.merge(
              newPropertiesData,
              into: existingPropertiesData)
            expect(result).to(equal(newPropertiesData))
          }
        }
      }

      context("when there is existing data about properties") {
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

        it("merges the existing data with new data") {
          let newPropertiesData: Set<PropertyData> = [
            .init(
              name: "thing",
              typeAnnotation: "String",
              comment: "",
              modifiers: [.public, .instance])
          ]

          let result = TypeSyntaxVisitor.merge(
            newPropertiesData,
            into: existingPropertiesData)

          expect(result).to(equal(existingPropertiesData.union(newPropertiesData)))
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
          expect(sut.propertiesData).to(beEmpty())
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
          expect(sut.propertiesData).to(beNil())
        }

        it("detects the properties") {
          try VisitorExecutor.walkVisitor(sut, overContent: content)
          expect(sut.propertiesData) == [
            PropertyData(
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
          let expectedPropSet: Set<PropertyData> = [
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
          expect(sut.propertiesData) == expectedPropSet
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
          expect(sut.propertiesData) == [
            PropertyData(
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
          expect(sut.propertiesData) == [
            PropertyData(
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
          expect(sut.propertiesData) == [
            PropertyData(
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
              expect(sut.propertiesData) == [
                PropertyData(
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
              expect(sut.propertiesData) == [
                PropertyData(
                  name: "thing",
                  typeAnnotation: "String",
                  comment: "",
                  modifiers: [.internal, .instance]),
                PropertyData(
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
            expect(sut.propertiesData) == [
              PropertyData(
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
          let expectedPropSet: Set<PropertyData> = [
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
          expect(sut.propertiesData) == expectedPropSet
        }
      }

      context("when there are multiple properties on the same line") {
        let content = """
        public final class FakeType {
          public var thing: String, foo: Int
        }
        """

        it("detects the properties") {
          try VisitorExecutor.walkVisitor(sut, overContent: content)
          let expectedPropSet: Set<PropertyData> = [
            .init(
              name: "thing",
              typeAnnotation: "String",
              comment: "",
              modifiers: [.public, .instance]),
            .init(
              name: "foo",
              typeAnnotation: "Int",
              comment: "",
              modifiers: [.public, .instance])
          ]
          expect(sut.propertiesData) == expectedPropSet
        }
      }

      context("when there is a static property") {
        let content = """
        public final class FakeType {
          public static var thing: String = "Hello, World"
        }
        """

        it("detects the property") {
          try VisitorExecutor.walkVisitor(sut, overContent: content)
          expect(sut.propertiesData) == [
            PropertyData(
              name: "thing",
              typeAnnotation: "String",
              comment: "",
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
          try VisitorExecutor.walkVisitor(sut, overContent: content)
          expect(sut.propertiesData) == [
            PropertyData(
              name: "thing",
              typeAnnotation: "String",
              comment: "",
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
          try VisitorExecutor.walkVisitor(sut, overContent: content)
          expect(sut.propertiesData) == [
            PropertyData(
              name: "thing",
              typeAnnotation: "String",
              comment: "",
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
          try VisitorExecutor.walkVisitor(sut, overContent: content)
          expect(sut.propertiesData) == [
            PropertyData(
              name: "thing",
              typeAnnotation: "String",
              comment: "",
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
          try VisitorExecutor.walkVisitor(sut, overContent: content)
          expect(sut.propertiesData) == [
            PropertyData(
              name: "thing",
              typeAnnotation: "String",
              comment: "",
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
          try VisitorExecutor.walkVisitor(sut, overContent: content)
          expect(sut.propertiesData) == [
            PropertyData(
              name: "thing",
              typeAnnotation: "String",
              comment: "",
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
          try VisitorExecutor.walkVisitor(sut, overContent: content)
          expect(sut.propertiesData) == [
            PropertyData(
              name: "thing",
              typeAnnotation: "String",
              comment: "",
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
          try VisitorExecutor.walkVisitor(sut, overContent: content)
          expect(sut.propertiesData) == [
            PropertyData(
              name: "thing",
              typeAnnotation: nil,
              comment: "",
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
          try VisitorExecutor.walkVisitor(sut, overContent: content)
          expect(sut.propertiesData) == [
            PropertyData(
              name: "thing",
              typeAnnotation: nil,
              comment: "",
              modifiers: [.public, .instance])
          ]
        }
      }

      context("when there is a line comment") {
        let content = """
        public final class FakeType {
          // The thing
          public var thing: String = "Hello, World"
        }
        """

        it("detects the property with the comment") {
          try VisitorExecutor.walkVisitor(sut, overContent: content)
          expect(sut.propertiesData) == [
            PropertyData(
              name: "thing",
              typeAnnotation: "String",
              comment: "// The thing",
              modifiers: [.public, .instance])
          ]
        }
      }

      context("when there is a multi-line comment") {
        let content = """
        public final class FakeType {
          // The thing
          // is such a thing
          public var thing: String = "Hello, World"
        }
        """

        it("detects the property with the comment") {
          try VisitorExecutor.walkVisitor(sut, overContent: content)
          expect(sut.propertiesData) == [
            PropertyData(
              name: "thing",
              typeAnnotation: "String",
              comment: "// The thing\n// is such a thing",
              modifiers: [.public, .instance])
          ]
        }
      }

      context("when there is a doc line comment") {
        let content = """
        public final class FakeType {
          /// The thing
          public var thing: String = "Hello, World"
        }
        """

        it("detects the property with the comment") {
          try VisitorExecutor.walkVisitor(sut, overContent: content)
          expect(sut.propertiesData) == [
            PropertyData(
              name: "thing",
              typeAnnotation: "String",
              comment: "/// The thing",
              modifiers: [.public, .instance])
          ]
        }
      }

      context("when there is a block comment") {
        let content = """
        public final class FakeType {
          /* The thing */
          public var thing: String = "Hello, World"
        }
        """

        it("detects the property with the comment") {
          try VisitorExecutor.walkVisitor(sut, overContent: content)
          expect(sut.propertiesData) == [
            PropertyData(
              name: "thing",
              typeAnnotation: "String",
              comment: "/* The thing */",
              modifiers: [.public, .instance])
          ]
        }
      }

      context("when there is a doc block comment") {
        let content = """
        public final class FakeType {
          /** The thing */
          public var thing: String = "Hello, World"
        }
        """

        it("detects the property with the comment") {
          try VisitorExecutor.walkVisitor(sut, overContent: content)
          expect(sut.propertiesData) == [
            PropertyData(
              name: "thing",
              typeAnnotation: "String",
              comment: "/** The thing */",
              modifiers: [.public, .instance])
          ]
        }
      }

    }
  }
}
