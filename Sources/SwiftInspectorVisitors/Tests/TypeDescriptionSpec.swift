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
      let encoder = JSONEncoder()
      let decoder = JSONDecoder()
      var data: Data!
      var sut: TypeDescription!

      context("when decoding a simple type") {
        beforeEach {
          sut = .simple(name: "Foo")
          data = try? encoder.encode(sut)
        }

        it("to decode the encoded type description") {
          expect(try decoder.decode(TypeDescription.self, from: data)) == sut
        }
      }

      context("when decoding a member type") {
        beforeEach {
          sut = .member(name: "Bar", baseType: .simple(name: "Foo"))
          data = try? encoder.encode(sut)
        }

        it("to decode the encoded type description") {
          expect(try decoder.decode(TypeDescription.self, from: data)) == sut
        }
      }

      context("when decoding an optional type") {
        beforeEach {
          sut = .optional(.simple(name: "Foo"))
          data = try? encoder.encode(sut)
        }

        it("to decode the encoded type description") {
          expect(try decoder.decode(TypeDescription.self, from: data)) == sut
        }
      }

      context("when decoding an implicitlyUnwrapped type") {
        beforeEach {
          sut = .implicitlyUnwrapped(.simple(name: "Foo"))
          data = try? encoder.encode(sut)
        }

        it("to decode the encoded type description") {
          expect(try decoder.decode(TypeDescription.self, from: data)) == sut
        }
      }

      context("when decoding an array type") {
        beforeEach {
          sut = .array(.simple(name: "Foo"))
          data = try? encoder.encode(sut)
        }

        it("to decode the encoded type description") {
          expect(try decoder.decode(TypeDescription.self, from: data)) == sut
        }
      }

      context("when decoding a dictionary type") {
        beforeEach {
          sut = .dictionary(key: .simple(name: "Foo"), value: .simple(name: "Bar"))
          data = try? encoder.encode(sut)
        }

        it("to decode the encoded type description") {
          expect(try decoder.decode(TypeDescription.self, from: data)) == sut
        }
      }

      context("when decoding a dictionary type") {
        beforeEach {
          sut = .composition([.simple(name: "Foo"), .optional(.simple(name: "Bar"))])
          data = try? encoder.encode(sut)
        }

        it("to decode the encoded compositionDescription description") {
          expect(try decoder.decode(TypeDescription.self, from: data)) == sut
        }
      }

      context("when decoding a tuple type") {
        beforeEach {
          sut = .tuple([.simple(name: "Foo"), .optional(.simple(name: "Bar"))])
          data = try? encoder.encode(sut)
        }

        it("to decode the encoded type description") {
          expect(try decoder.decode(TypeDescription.self, from: data)) == sut
        }
      }

      context("when decoding an unknown type") {
        beforeEach {
          sut = .unknown(text: "Foo")
          data = try? encoder.encode(sut)
        }

        it("to decode the encoded type description") {
          expect(try decoder.decode(TypeDescription.self, from: data)) == sut
        }
      }

      context("when decoding an unknown case") {
        beforeEach {
          data = try? encoder.encode("garbage")
        }

        it("throws") {
          expect(try decoder.decode(TypeDescription.self, from: data)).to(throwError())
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
          expect(visitor?.simpleTypeIdentifier?.description) == "Int"
        }
      }

      context("when called on a TypeSyntax node representing a MemberTypeIdentifierSyntax") {
        final class MemberTypeIdentifierSyntaxVisitor: SyntaxVisitor {
          var memberTypeIdentifier: TypeDescription?
          override func visit(_ node: MemberTypeIdentifierSyntax) -> SyntaxVisitorContinueKind {
            memberTypeIdentifier = TypeSyntax(node).typeDescription
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
          expect(visitor?.memberTypeIdentifier?.description) == "Swift.Int"
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
          expect(visitor?.composedTypeIdentifier?.description) == "Foo & Bar"
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
                  .map { $0.description }
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
          expect(visitor?.implictlyUnwrappedOptionalTypeIdentifier?.description)
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
          expect(visitor.arrayTypeIdentifier?.description) == "[Int]"
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
          expect(visitor.dictionaryTypeIdentifier?.description) == "[Int: String]"
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
          expect(visitor?.tupleTypeIdentifier?.description) == "(Int, String)"
        }
      }
    }
  }
}
