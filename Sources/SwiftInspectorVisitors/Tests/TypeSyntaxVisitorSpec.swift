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

    var fileURL: URL!
    var sut = PropertyAnalyzer(typeName: "FakeType")

    beforeEach {
      sut = PropertyAnalyzer(typeName: "FakeType")
    }

    afterEach {
      guard let fileURL = fileURL else {
        return
      }
      try? Temporary.removeItem(at: fileURL)
    }

    describe("analyze(fileURL:)") {
      context("when there are no properties") {
        beforeEach {
          let content = """
                        public final class FakeType {}
                        """
          fileURL = try? Temporary.makeFile(content: content)
        }

        it("returns type info with empty property list") {
          let result = try? sut.analyze(fileURL: fileURL)
          expect(result?.properties).to(beEmpty())
        }
      }

      context("when there is a property") {
        beforeEach {
          let content = """
          public final class FakeType {
            public var thing: String = "Hello, World"
          }
          """
          fileURL = try? Temporary.makeFile(content: content)
        }

        it("detects the type name") {
          let result = try? sut.analyze(fileURL: fileURL)
          expect(result?.name) == "FakeType"
        }

        it("returns nil if the type name is not present") {
          let sut = PropertyAnalyzer(typeName: "AnotherType")
          let result = try? sut.analyze(fileURL: fileURL)
          expect(result).to(beNil())
        }

        it("detects the properties") {
          let result = try? sut.analyze(fileURL: fileURL)
          expect(result?.properties) == [
            TypeProperties.PropertyData(
              name: "thing",
              typeAnnotation: "String",
              comment: "",
              modifiers: [.public, .instance])
          ]
        }
      }

      context("when there is a property in a nested type with the same type name") {
        beforeEach {
          let content = """
          public final class FakeType {
            public var thing: String = "Hello, World"

            enum FakeType {
              static let foo: String = "Hola"
            }
          }
          """
          fileURL = try? Temporary.makeFile(content: content)
        }

        it("detects the type name") {
          let result = try? sut.analyze(fileURL: fileURL)
          expect(result?.name) == "FakeType"
        }

        /*
         This is actually not the ideal result of this and is a limitation of the implementation
         Ideally you would have to pass in `FakeType.FakeType` to get this nested type's property
         information. For now we are accepting this limitation and have this test to showcase
         what happens in this scenario.
         */
        it("detects and merges the properties") {
          let result = try? sut.analyze(fileURL: fileURL)
          let propSet = Set(result?.properties ?? [])
          let expectedPropSet: Set<TypeProperties.PropertyData> = [
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
          expect(propSet) == expectedPropSet
        }
      }

      context("when there is a property (struct)") {
        beforeEach {
          let content = """
          public struct FakeType {
            public var thing: String = "Hello, World"
          }
          """
          fileURL = try? Temporary.makeFile(content: content)
        }

        it("detects the type name") {
          let result = try? sut.analyze(fileURL: fileURL)
          expect(result?.name) == "FakeType"
        }

        it("detects the properties") {
          let result = try? sut.analyze(fileURL: fileURL)
          expect(result?.properties) == [
            TypeProperties.PropertyData(
              name: "thing",
              typeAnnotation: "String",
              comment: "",
              modifiers: [.public, .instance])
          ]
        }
      }

      context("when there is a property (enum)") {
        beforeEach {
          let content = """
          public enum FakeType {
            public var thing: String = "Hello, World"
          }
          """
          fileURL = try? Temporary.makeFile(content: content)
        }

        it("detects the type name") {
          let result = try? sut.analyze(fileURL: fileURL)
          expect(result?.name) == "FakeType"
        }

        it("detects the properties") {
          let result = try? sut.analyze(fileURL: fileURL)
          expect(result?.properties) == [
            TypeProperties.PropertyData(
              name: "thing",
              typeAnnotation: "String",
              comment: "",
              modifiers: [.public, .instance])
          ]
        }
      }

      context("when there is a property (protocol)") {
        beforeEach {
          let content = """
          public protocol FakeType {
            var thing: String { get }
          }
          """
          fileURL = try? Temporary.makeFile(content: content)
        }

        it("detects the type name") {
          let result = try? sut.analyze(fileURL: fileURL)
          expect(result?.name) == "FakeType"
        }

        it("detects the properties") {
          let result = try? sut.analyze(fileURL: fileURL)
          expect(result?.properties) == [
            TypeProperties.PropertyData(
              name: "thing",
              typeAnnotation: "String",
              comment: "",
              modifiers: [.internal, .instance])
          ]
        }
      }

      context("when there is a property extension") {
        beforeEach {
          let content = """
          public class FakeType { }

          extension FakeType {
            var thing: String = "Hello, World"
          }
          """
          fileURL = try? Temporary.makeFile(content: content)
        }

        it("detects the type name") {
          let result = try? sut.analyze(fileURL: fileURL)
          expect(result?.name) == "FakeType"
        }

        it("detects the properties") {
          let result = try? sut.analyze(fileURL: fileURL)
          expect(result?.properties) == [
            TypeProperties.PropertyData(
              name: "thing",
              typeAnnotation: "String",
              comment: "",
              modifiers: [.internal, .instance])
          ]
        }
      }

      context("when there are multiple properties") {
        beforeEach {
          let content = """
          public final class FakeType {
            public var thing: String = "Hello, World"
            var foo: Int = 4
          }
          """
          fileURL = try? Temporary.makeFile(content: content)
        }

        it("detects the properties") {
          let result = try? sut.analyze(fileURL: fileURL)
          let propSet = Set(result?.properties ?? [])
          let expectedPropSet: Set<TypeProperties.PropertyData> = [
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
          expect(propSet) == expectedPropSet
        }
      }

      context("when there are multiple properties on the same line") {
        beforeEach {
          let content = """
          public final class FakeType {
            public var thing: String, foo: Int
          }
          """
          fileURL = try? Temporary.makeFile(content: content)
        }

        it("detects the properties") {
          let result = try? sut.analyze(fileURL: fileURL)
          let propSet = Set(result?.properties ?? [])
          let expectedPropSet: Set<TypeProperties.PropertyData> = [
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
          expect(propSet) == expectedPropSet
        }
      }

      context("when there is a static property") {
        beforeEach {
          let content = """
          public final class FakeType {
            public static var thing: String = "Hello, World"
          }
          """
          fileURL = try? Temporary.makeFile(content: content)
        }

        it("detects the property") {
          let result = try? sut.analyze(fileURL: fileURL)
          expect(result?.properties) == [
            TypeProperties.PropertyData(
              name: "thing",
              typeAnnotation: "String",
              comment: "",
              modifiers: [.public, .static])
          ]
        }
      }

      context("when there is a static property in reverse order") {
        beforeEach {
          let content = """
          public final class FakeType {
            static public var thing: String = "Hello, World"
          }
          """
          fileURL = try? Temporary.makeFile(content: content)
        }

        it("detects the property") {
          let result = try? sut.analyze(fileURL: fileURL)
          expect(result?.properties) == [
            TypeProperties.PropertyData(
              name: "thing",
              typeAnnotation: "String",
              comment: "",
              modifiers: [.public, .static])
          ]
        }
      }

      context("when there is a private property") {
        beforeEach {
          let content = """
          public final class FakeType {
            private static var thing: String = "Hello, World"
          }
          """
          fileURL = try? Temporary.makeFile(content: content)
        }

        it("detects the property") {
          let result = try? sut.analyze(fileURL: fileURL)
          expect(result?.properties) == [
            TypeProperties.PropertyData(
              name: "thing",
              typeAnnotation: "String",
              comment: "",
              modifiers: [.private, .static])
          ]
        }
      }

      context("when there is a public private(set) property") {
        beforeEach {
          let content = """
          public final class FakeType {
            public private(set) var thing: String = "Hello, World"
          }
          """
          fileURL = try? Temporary.makeFile(content: content)
        }

        it("detects the property") {
          let result = try? sut.analyze(fileURL: fileURL)
          expect(result?.properties) == [
            TypeProperties.PropertyData(
              name: "thing",
              typeAnnotation: "String",
              comment: "",
              modifiers: [.public, .privateSet, .instance])
          ]
        }
      }

      context("when there is a public internal(set) property") {
        beforeEach {
          let content = """
          public final class FakeType {
            public internal(set) var thing: String = "Hello, World"
          }
          """
          fileURL = try? Temporary.makeFile(content: content)
        }

        it("detects the property") {
          let result = try? sut.analyze(fileURL: fileURL)
          expect(result?.properties) == [
            TypeProperties.PropertyData(
              name: "thing",
              typeAnnotation: "String",
              comment: "",
              modifiers: [.public, .internalSet, .instance])
          ]
        }
      }

      context("when there is a internal public(set) property") {
        beforeEach {
          let content = """
          public final class FakeType {
            internal public(set) var thing: String = "Hello, World"
          }
          """
          fileURL = try? Temporary.makeFile(content: content)
        }

        it("detects the property") {
          let result = try? sut.analyze(fileURL: fileURL)
          expect(result?.properties) == [
            TypeProperties.PropertyData(
              name: "thing",
              typeAnnotation: "String",
              comment: "",
              modifiers: [.publicSet, .internal, .instance])
          ]
        }
      }

      context("when there is a fileprivate property") {
        beforeEach {
          let content = """
          public final class FakeType {
            fileprivate static var thing: String = "Hello, World"
          }
          """
          fileURL = try? Temporary.makeFile(content: content)
        }

        it("detects the property") {
          let result = try? sut.analyze(fileURL: fileURL)
          expect(result?.properties) == [
            TypeProperties.PropertyData(
              name: "thing",
              typeAnnotation: "String",
              comment: "",
              modifiers: [.fileprivate, .static])
          ]
        }
      }

      context("when there is no type annotation") {
        beforeEach {
          let content = """
          public final class FakeType {
            private static var thing = "Hello, World"
          }
          """
          fileURL = try? Temporary.makeFile(content: content)
        }

        it("detects the property with no type information") {
          let result = try? sut.analyze(fileURL: fileURL)
          expect(result?.properties) == [
            TypeProperties.PropertyData(
              name: "thing",
              typeAnnotation: nil,
              comment: "",
              modifiers: [.private, .static])
          ]
        }
      }

      context("when there is a property attribute") {
        beforeEach {
          let content = """
          public final class FakeType {
            @objc public var thing = "Hello, World"
          }
          """
          fileURL = try? Temporary.makeFile(content: content)
        }

        it("detects the property with no type information") {
          let result = try? sut.analyze(fileURL: fileURL)
          expect(result?.properties) == [
            TypeProperties.PropertyData(
              name: "thing",
              typeAnnotation: nil,
              comment: "",
              modifiers: [.public, .instance])
          ]
        }
      }

      context("when there is a line comment") {
        beforeEach {
          let content = """
          public final class FakeType {
            // The thing
            public var thing: String = "Hello, World"
          }
          """
          fileURL = try? Temporary.makeFile(content: content)
        }

        it("detects the property with the comment") {
          let result = try? sut.analyze(fileURL: fileURL)
          expect(result?.properties) == [
            TypeProperties.PropertyData(
              name: "thing",
              typeAnnotation: "String",
              comment: "// The thing",
              modifiers: [.public, .instance])
          ]
        }
      }

      context("when there is a multi-line comment") {
        beforeEach {
          let content = """
          public final class FakeType {
            // The thing
            // is such a thing
            public var thing: String = "Hello, World"
          }
          """
          fileURL = try? Temporary.makeFile(content: content)
        }

        it("detects the property with the comment") {
          let result = try? sut.analyze(fileURL: fileURL)
          expect(result?.properties) == [
            TypeProperties.PropertyData(
              name: "thing",
              typeAnnotation: "String",
              comment: "// The thing\n// is such a thing",
              modifiers: [.public, .instance])
          ]
        }
      }

      context("when there is a doc line comment") {
        beforeEach {
          let content = """
          public final class FakeType {
            /// The thing
            public var thing: String = "Hello, World"
          }
          """
          fileURL = try? Temporary.makeFile(content: content)
        }

        it("detects the property with the comment") {
          let result = try? sut.analyze(fileURL: fileURL)
          expect(result?.properties) == [
            TypeProperties.PropertyData(
              name: "thing",
              typeAnnotation: "String",
              comment: "/// The thing",
              modifiers: [.public, .instance])
          ]
        }
      }

      context("when there is a block comment") {
        beforeEach {
          let content = """
          public final class FakeType {
            /* The thing */
            public var thing: String = "Hello, World"
          }
          """
          fileURL = try? Temporary.makeFile(content: content)
        }

        it("detects the property with the comment") {
          let result = try? sut.analyze(fileURL: fileURL)
          expect(result?.properties) == [
            TypeProperties.PropertyData(
              name: "thing",
              typeAnnotation: "String",
              comment: "/* The thing */",
              modifiers: [.public, .instance])
          ]
        }
      }

      context("when there is a doc block comment") {
        beforeEach {
          let content = """
          public final class FakeType {
            /** The thing */
            public var thing: String = "Hello, World"
          }
          """
          fileURL = try? Temporary.makeFile(content: content)
        }

        it("detects the property with the comment") {
          let result = try? sut.analyze(fileURL: fileURL)
          expect(result?.properties) == [
            TypeProperties.PropertyData(
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
