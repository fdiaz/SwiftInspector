// Created by Dan Federman on 2/2/21.
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

import Foundation
import Nimble
import Quick
import SwiftInspectorTestHelpers
import SwiftSyntax

@testable import SwiftInspectorVisitors

final class TypeDescriptionSpec: QuickSpec {

  override func spec() {
    describe("init(from decoder: Decoder)") {
      let decoder = JSONDecoder()
      var data: Data!

      context("when decoding a simple type") {
        beforeEach {
          data = "{\"caseDescription\":\"simple\",\"text\":\"Foo\"}".data(using: .utf8)
        }

        it("decodes the encoded type description") {
          expect(try decoder.decode(TypeDescription.self, from: data)) == .simple(name: "Foo")
        }
      }

      context("when decoding a nested type") {
        beforeEach {
          data = "{\"caseDescription\":\"nested\",\"text\":\"Bar\",\"typeDescription\":{\"caseDescription\":\"simple\",\"text\":\"Foo\"}}".data(using: .utf8)
        }

        it("decodes the encoded type description") {
          expect(try decoder.decode(TypeDescription.self, from: data)) == .nested(name: "Bar", parentType: .simple(name: "Foo"))
        }
      }

      context("when decoding an optional type") {
        beforeEach {
          data = "{\"caseDescription\":\"optional\",\"typeDescription\":{\"caseDescription\":\"simple\",\"text\":\"Foo\"}}".data(using: .utf8)
        }

        it("decodes the encoded type description") {
          expect(try decoder.decode(TypeDescription.self, from: data)) == .optional(.simple(name: "Foo"))
        }
      }

      context("when decoding an implicitlyUnwrappedOptional type") {
        beforeEach {
          data = "{\"caseDescription\":\"implicitlyUnwrappedOptional\",\"typeDescription\":{\"caseDescription\":\"simple\",\"text\":\"Foo\"}}".data(using: .utf8)
        }

        it("decodes the encoded type description") {
          expect(try decoder.decode(TypeDescription.self, from: data)) == .implicitlyUnwrappedOptional(.simple(name: "Foo"))
        }
      }

      context("when decoding an array type") {
        beforeEach {
          data = "{\"caseDescription\":\"array\",\"typeDescription\":{\"caseDescription\":\"simple\",\"text\":\"Foo\"}}".data(using: .utf8)
        }

        it("decodes the encoded type description") {
          expect(try decoder.decode(TypeDescription.self, from: data)) == .array(.simple(name: "Foo"))
        }
      }

      context("when decoding a dictionary type") {
        beforeEach {
          data = "{\"caseDescription\":\"dictionary\",\"typeDescriptionDictionaryKey\":{\"caseDescription\":\"simple\",\"text\":\"Foo\"},\"typeDescriptionDictionaryValue\":{\"caseDescription\":\"simple\",\"text\":\"Bar\"}}".data(using: .utf8)
        }

        it("decodes the encoded type description") {
          expect(try decoder.decode(TypeDescription.self, from: data)) == .dictionary(key: .simple(name: "Foo"), value: .simple(name: "Bar"))
        }
      }

      context("when decoding a composition type") {
        beforeEach {
          data = "{\"caseDescription\":\"composition\",\"typeDescriptions\":[{\"caseDescription\":\"simple\",\"text\":\"Foo\"},{\"caseDescription\":\"optional\",\"typeDescription\":{\"caseDescription\":\"simple\",\"text\":\"Bar\"}}]}".data(using: .utf8)
        }

        it("to decode the encoded composition description") {
          expect(try decoder.decode(TypeDescription.self, from: data)) == .composition([.simple(name: "Foo"), .optional(.simple(name: "Bar"))])
        }
      }

      context("when decoding a tuple type") {
        beforeEach {
          data = "{\"caseDescription\":\"tuple\",\"typeDescriptions\":[{\"caseDescription\":\"simple\",\"text\":\"Foo\"},{\"caseDescription\":\"optional\",\"typeDescription\":{\"caseDescription\":\"simple\",\"text\":\"Bar\"}}]}".data(using: .utf8)
        }

        it("decodes the encoded type description") {
          expect(try decoder.decode(TypeDescription.self, from: data)) == .tuple([.simple(name: "Foo"), .optional(.simple(name: "Bar"))])
        }
      }

      context("when decoding an unknown type") {
        beforeEach {
          data = "{\"caseDescription\":\"unknown\",\"text\":\"Foo\"}".data(using: .utf8)
        }

        it("decodes the encoded type description") {
          expect(try decoder.decode(TypeDescription.self, from: data)) == .unknown(text: "Foo")
        }
      }

      context("when decoding an unknown case") {
        beforeEach {
          data = "{\"caseDescription\": \"garbage\"}".data(using: .utf8)
        }

        it("throws") {
          expect(try decoder.decode(TypeDescription.self, from: data)).to(throwError(TypeDescription.CodingError.unknownCase))
        }
      }
    }

    describe("encode(to encoder: Encoder)") {
      let encoder = JSONEncoder()
      var data: Data!
      var sut: TypeDescription!

      context("when encoding a simple type") {
        beforeEach {
          sut = .simple(name: "Foo")
          data = "{\"caseDescription\":\"simple\",\"text\":\"Foo\"}".data(using: .utf8)
        }

        it("successfully encodes the data") {
          expect(try encoder.encode(sut)) == data
        }
      }

      context("when encoding a nested type") {
        beforeEach {
          sut = .nested(name: "Bar", parentType: .simple(name: "Foo"))
          data = "{\"caseDescription\":\"nested\",\"text\":\"Bar\",\"typeDescription\":{\"caseDescription\":\"simple\",\"text\":\"Foo\"}}".data(using: .utf8)
        }

        it("successfully encodes the data") {
          expect(try encoder.encode(sut)) == data
        }
      }

      context("when encoding an optional type") {
        beforeEach {
          sut = .optional(.simple(name: "Foo"))
          data = "{\"caseDescription\":\"optional\",\"typeDescription\":{\"caseDescription\":\"simple\",\"text\":\"Foo\"}}".data(using: .utf8)
        }

        it("successfully encodes the data") {
          expect(try encoder.encode(sut)) == data
        }
      }

      context("when encoding an implicitlyUnwrappedOptional type") {
        beforeEach {
          sut = .implicitlyUnwrappedOptional(.simple(name: "Foo"))
          data = "{\"caseDescription\":\"implicitlyUnwrappedOptional\",\"typeDescription\":{\"caseDescription\":\"simple\",\"text\":\"Foo\"}}".data(using: .utf8)
        }

        it("successfully encodes the data") {
          expect(try encoder.encode(sut)) == data
        }
      }

      context("when encoding an array type") {
        beforeEach {
          sut = .array(.simple(name: "Foo"))
          data = "{\"caseDescription\":\"array\",\"typeDescription\":{\"caseDescription\":\"simple\",\"text\":\"Foo\"}}".data(using: .utf8)
        }

        it("successfully encodes the data") {
          expect(try encoder.encode(sut)) == data
        }
      }

      context("when encoding a dictionary type") {
        beforeEach {
          sut = .dictionary(key: .simple(name: "Foo"), value: .simple(name: "Bar"))
          data = "{\"caseDescription\":\"dictionary\",\"typeDescriptionDictionaryKey\":{\"caseDescription\":\"simple\",\"text\":\"Foo\"},\"typeDescriptionDictionaryValue\":{\"caseDescription\":\"simple\",\"text\":\"Bar\"}}".data(using: .utf8)
        }

        it("successfully encodes the data") {
          expect(try encoder.encode(sut)) == data
        }
      }

      context("when encoding a composition type") {
        beforeEach {
          sut = .composition([.simple(name: "Foo"), .optional(.simple(name: "Bar"))])
          data = "{\"caseDescription\":\"composition\",\"typeDescriptions\":[{\"caseDescription\":\"simple\",\"text\":\"Foo\"},{\"caseDescription\":\"optional\",\"typeDescription\":{\"caseDescription\":\"simple\",\"text\":\"Bar\"}}]}".data(using: .utf8)
        }

        it("to decode the encoded composition description") {
          expect(try encoder.encode(sut)) == data
        }
      }

      context("when encoding a tuple type") {
        beforeEach {
          sut = .tuple([.simple(name: "Foo"), .optional(.simple(name: "Bar"))])
          data = "{\"caseDescription\":\"tuple\",\"typeDescriptions\":[{\"caseDescription\":\"simple\",\"text\":\"Foo\"},{\"caseDescription\":\"optional\",\"typeDescription\":{\"caseDescription\":\"simple\",\"text\":\"Bar\"}}]}".data(using: .utf8)
        }

        it("successfully encodes the data") {
          expect(try encoder.encode(sut)) == data
        }
      }

      context("when encoding an unknown type") {
        beforeEach {
          sut = .unknown(text: "Foo")
          data = "{\"caseDescription\":\"unknown\",\"text\":\"Foo\"}".data(using: .utf8)
        }

        it("successfully encodes the data") {
          expect(try encoder.encode(sut)) == data
        }
      }
    }

    describe("typeDescription") {
      context("when called on a TypeSyntax node representing a SimpleTypeIdentifierSyntax") {
        final class SimpleTypeIdentifierSyntaxVisitor: SyntaxVisitor {
          var simpleTypeIdentifier: TypeDescription?
          override func visit(_ node: SimpleTypeIdentifierSyntax) -> SyntaxVisitorContinueKind {
            simpleTypeIdentifier = TypeSyntax(node).typeDescription
            return .skipChildren
          }
        }

        var visitor: SimpleTypeIdentifierSyntaxVisitor!
        beforeEach {
          let content = """
              var int: Int = 1
              """

          visitor = SimpleTypeIdentifierSyntaxVisitor()
          try? VisitorExecutor.walkVisitor(visitor, overContent: content)
        }

        it("Finds the type") {
          expect(visitor?.simpleTypeIdentifier?.asSource) == "Int"
        }
      }

      context("when called on a TypeSyntax node representing a MemberTypeIdentifierSyntax") {
        final class MemberTypeIdentifierSyntaxVisitor: SyntaxVisitor {
          var nestedTypeIdentifier: TypeDescription?
          override func visit(_ node: MemberTypeIdentifierSyntax) -> SyntaxVisitorContinueKind {
            nestedTypeIdentifier = TypeSyntax(node).typeDescription
            return .skipChildren
          }
        }

        var visitor: MemberTypeIdentifierSyntaxVisitor!
        beforeEach {
          let content = """
              var int: Swift.Int = 1
              """

          visitor = MemberTypeIdentifierSyntaxVisitor()
          try? VisitorExecutor.walkVisitor(visitor, overContent: content)
        }

        it("Finds the type") {
          expect(visitor?.nestedTypeIdentifier?.asSource) == "Swift.Int"
        }
      }

      context("when called on a TypeSyntax node representing a CompositionTypeSyntax") {
        final class CompositionTypeSyntaxVisitor: SyntaxVisitor {
          var composedTypeIdentifier: TypeDescription?
          // Note: ideally we'd visit a node of type CompositionTypeElementListSyntax
          // but there's no easy way to get a TypeSyntax from an object of that type.
          override func visit(_ node: InheritedTypeSyntax) -> SyntaxVisitorContinueKind {
            composedTypeIdentifier = node.typeName.typeDescription
            return .skipChildren
          }
        }

        var visitor: CompositionTypeSyntaxVisitor!
        beforeEach {
          let content = """
            protocol FooBar: Foo & Bar
            """

          visitor = CompositionTypeSyntaxVisitor()
          try? VisitorExecutor.walkVisitor(visitor, overContent: content)
        }

        it("Finds the types") {
          expect(visitor?.composedTypeIdentifier?.asSource) == "Foo & Bar"
        }
      }

      context("when called on a TypeSyntax node representing a OptionalTypeSyntax") {
        final class OptionalTypeSyntaxVisitor: SyntaxVisitor {
          var optionalTypeIdentifiers = [TypeDescription]()
          override func visit(_ node: SameTypeRequirementSyntax) -> SyntaxVisitorContinueKind {
            optionalTypeIdentifiers += [
              node.leftTypeIdentifier.typeDescription,
              node.rightTypeIdentifier.typeDescription
            ]
            return .skipChildren
          }
        }

        var visitor: OptionalTypeSyntaxVisitor!
        beforeEach {
          let content = """
            protocol FooBar: Foo where Something == AnyObject? {}
            """

          visitor = OptionalTypeSyntaxVisitor()
          try? VisitorExecutor.walkVisitor(visitor, overContent: content)
        }

        it("Finds the type") {
          expect(visitor?.optionalTypeIdentifiers
                  .map { $0.asSource }
                  .contains("AnyObject?"))
            .to(beTrue())
        }
      }

      context("when called on a TypeSyntax node representing a ImplicitlyUnwrappedOptionalTypeSyntax") {
        final class ImplicitlyUnwrappedOptionalTypeSyntaxVisitor: SyntaxVisitor {
          var implictlyUnwrappedOptionalTypeIdentifier: TypeDescription?
          override func visit(_ node: ImplicitlyUnwrappedOptionalTypeSyntax) -> SyntaxVisitorContinueKind {
            implictlyUnwrappedOptionalTypeIdentifier = TypeSyntax(node).typeDescription
            return .skipChildren
          }
        }

        var visitor: ImplicitlyUnwrappedOptionalTypeSyntaxVisitor!
        beforeEach {
          let content = """
            var int: Int!
            """

          visitor = ImplicitlyUnwrappedOptionalTypeSyntaxVisitor()
          try? VisitorExecutor.walkVisitor(visitor, overContent: content)
        }

        it("Finds the type") {
          expect(visitor?.implictlyUnwrappedOptionalTypeIdentifier?.asSource)
            == "Int!"
        }
      }

      context("when called on a TypeSyntax node representing an ArrayTypeSyntax") {
        final class ArrayTypeSyntaxVisitor: SyntaxVisitor {
          var arrayTypeIdentifier: TypeDescription?
          override func visit(_ node: ArrayTypeSyntax) -> SyntaxVisitorContinueKind {
            arrayTypeIdentifier = TypeSyntax(node).typeDescription
            return .skipChildren
          }
        }

        var visitor: ArrayTypeSyntaxVisitor!
        beforeEach {
          let content = """
            var intArray: [Int] = [Int]()
            """

          visitor = ArrayTypeSyntaxVisitor()
          try? VisitorExecutor.walkVisitor(visitor, overContent: content)
        }

        it("Finds the type") {
          expect(visitor.arrayTypeIdentifier?.asSource) == "[Int]"
        }
      }

      context("when called on a TypeSyntax node representing an DictionaryTypeSyntax") {
        final class DictionaryTypeSyntaxVisitor: SyntaxVisitor {
          var dictionaryTypeIdentifier: TypeDescription?
          override func visit(_ node: DictionaryTypeSyntax) -> SyntaxVisitorContinueKind {
            dictionaryTypeIdentifier = TypeSyntax(node).typeDescription
            return .skipChildren
          }
        }

        var visitor: DictionaryTypeSyntaxVisitor!
        beforeEach {
          let content = """
            var dictionary: [Int: String] = [Int: String]()
            """

          visitor = DictionaryTypeSyntaxVisitor()
          try? VisitorExecutor.walkVisitor(visitor, overContent: content)
        }

        it("Finds the type") {
          expect(visitor.dictionaryTypeIdentifier?.asSource) == "[Int: String]"
        }
      }

      context("when called on a TypeSyntax node representing a TupleTypeSyntax") {
        final class TupleTypeSyntaxVisitor: SyntaxVisitor {
          var tupleTypeIdentifier: TypeDescription?
          // Note: ideally we'd visit a node of type TupleTypeElementListSyntax
          // but there's no easy way to get a TypeSyntax from an object of that type.
          override func visit(_ node: TypeAnnotationSyntax) -> SyntaxVisitorContinueKind {
            tupleTypeIdentifier = node.type.typeDescription
            return .skipChildren
          }
        }

        var visitor: TupleTypeSyntaxVisitor!
        beforeEach {
          let content = """
              var tuple: (Int, String)
              """

          visitor = TupleTypeSyntaxVisitor()
          try? VisitorExecutor.walkVisitor(visitor, overContent: content)
        }

        it("Finds the type") {
          expect(visitor?.tupleTypeIdentifier?.asSource) == "(Int, String)"
        }
      }

      context("when called on a TypeSyntax node representing a ClassRestrictionTypeSyntax") {
        final class ClassRestrictionTypeSyntaxVisitor: SyntaxVisitor {
          var classRestrictionIdentifier: TypeDescription?
          // Note: ideally we'd visit a node of type ClassRestrictionTypeSyntax
          // but there's no way to get a TypeSyntax from an object of that type.
          override func visit(_ node: InheritedTypeSyntax) -> SyntaxVisitorContinueKind {
            classRestrictionIdentifier = node.typeName.typeDescription
            return .skipChildren
          }
        }

        var visitor: ClassRestrictionTypeSyntaxVisitor!
        beforeEach {
          let content = """
              protocol SomeObject: class {}
              """

          visitor = ClassRestrictionTypeSyntaxVisitor()
          try? VisitorExecutor.walkVisitor(visitor, overContent: content)
        }

        it("Finds returns the type as AnyObject") {
          expect(visitor?.classRestrictionIdentifier?.asSource) == "AnyObject"
        }
      }
    }

    describe("asSource") {
      context("when describing an unknown case") {
        let sut = TypeDescription.unknown(text: " SomeTypeThatIsFormattedOddly  ")

        it("returns the provided string with whitespace stripped") {
          expect(sut.asSource) == "SomeTypeThatIsFormattedOddly"
        }
      }
    }
  }
}
