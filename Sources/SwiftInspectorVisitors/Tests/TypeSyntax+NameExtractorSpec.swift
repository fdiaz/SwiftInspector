// Created by Dan Federman on 2/1/21.
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

final class TypeSyntaxNameExtractorSpec: QuickSpec {
  private var sut = EnumVisitor()

  override func spec() {
    beforeEach {
      self.sut = EnumVisitor()
    }

    describe("qualifiedName") {
      context("when called on a TypeSyntax node representing a SimpleTypeIdentifierSyntax") {
        final class SimpleTypeIdentifierSyntaxVisitor: SyntaxVisitor {
          var simpleTypeIdentifiers: [String]?
          override func visit(_ node: SimpleTypeIdentifierSyntax) -> SyntaxVisitorContinueKind {
            simpleTypeIdentifiers = TypeSyntax(node).qualifiedNames
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
          expect(visitor?.simpleTypeIdentifiers?.first) == "Int"
        }
      }

      context("when called on a TypeSyntax node representing a MemberTypeIdentifierSyntax") {
        final class MemberTypeIdentifierSyntaxVisitor: SyntaxVisitor {
          var memberTypeIdentifiers: [String]?
          override func visit(_ node: MemberTypeIdentifierSyntax) -> SyntaxVisitorContinueKind {
            memberTypeIdentifiers = TypeSyntax(node).qualifiedNames
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
          expect(visitor?.memberTypeIdentifiers?.first) == "Swift.Int"
        }
      }

      context("when called on a TypeSyntax node representing a CompositionTypeSyntax") {
        final class CompositionTypeSyntaxVisitor: SyntaxVisitor {
          var composedTypeIdentifiers: [String]?
          // Note: ideally we'd visit a node of type CompositionTypeElementListSyntax
          // but there's no easy way to get a TypeSyntax from an object of that type.
          override func visit(_ node: InheritedTypeSyntax) -> SyntaxVisitorContinueKind {
            composedTypeIdentifiers = node.typeName.qualifiedNames
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
          expect(visitor?.composedTypeIdentifiers?.first) == "Foo"
          expect(visitor?.composedTypeIdentifiers?.last) == "Bar"
        }
      }

      context("when called on a TypeSyntax node representing an Array") {
        final class ArraySyntaxVisitor: SyntaxVisitor {
          override func visit(_ node: ArrayTypeSyntax) -> SyntaxVisitorContinueKind {
            // This line should assert.
            _ = TypeSyntax(node).qualifiedNames
            fail("This line should never be reached")
            return .skipChildren
          }
        }

        it("asserts") {
          expect(try VisitorExecutor.walkVisitor(
                  ArraySyntaxVisitor(),
                  overContent: """
                    var intArray: [Int] = [Int]()
                    """))
            .to(throwAssertion())
        }
      }
    }
  }
}
