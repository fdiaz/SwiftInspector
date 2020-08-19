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

@testable import SwiftInspectorCore

final class PropertyAnalyzerSpec: QuickSpec {
  override func spec() {
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
              modifier: [.public, .instance])
          ]
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
              modifier: [.public, .instance])
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
              modifier: [.public, .instance])
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
              modifier: [.internal, .instance])
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
              modifier: [.internal, .instance])
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
              modifier: [.public, .instance]),
            .init(
              name: "foo",
              typeAnnotation: "Int",
              comment: "",
              modifier: [.internal, .instance])
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
              modifier: [.public, .instance]),
            .init(
              name: "foo",
              typeAnnotation: "Int",
              comment: "",
              modifier: [.public, .instance])
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
              modifier: [.public, .static])
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
              modifier: [.public, .static])
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
              modifier: [.private, .static])
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
              modifier: [.public, .privateSet, .instance])
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
              modifier: [.fileprivate, .static])
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
              modifier: [.private, .static])
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
              modifier: [.public, .instance])
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
              modifier: [.public, .instance])
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
              modifier: [.public, .instance])
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
              modifier: [.public, .instance])
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
              modifier: [.public, .instance])
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
              modifier: [.public, .instance])
          ]
        }
      }

    }
  }
}
