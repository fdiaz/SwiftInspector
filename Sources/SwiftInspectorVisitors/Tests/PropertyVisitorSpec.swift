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
import SwiftSyntax
import Quick
import Nimble

@testable import SwiftInspectorVisitors

// MARK: - PropertyVisitorSpec

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
              typeDescription: .simple(name: "String"),
              modifiers: [.public, .instance],
              paradigm: .undefinedVariable),
            .init(
              name: "foo",
              typeDescription: .simple(name: "Int"),
              modifiers: [.public, .instance],
              paradigm: .undefinedVariable)
          ]
          expect(sut.properties).to(contain(expected))
        }

        it("detects properties with the same type") {
          try sut.walkContent(content)
          let expected: [PropertyInfo] = [
            .init(
              name: "green",
              typeDescription: .simple(name: "Double"),
              modifiers: [.internal, .instance],
              paradigm: .undefinedConstant),
            .init(
              name: "red",
              typeDescription: .simple(name: "Double"),
              modifiers: [.internal, .instance],
              paradigm: .undefinedConstant),
            .init(
              name: "blue",
              typeDescription: .simple(name: "Double"),
              modifiers: [.internal, .instance],
              paradigm: .undefinedConstant)
          ]
          expect(sut.properties).to(contain(expected))
        }

        it("detects properties in a line with both different and equal types") {
          try sut.walkContent(content)
          let expected: [PropertyInfo] = [
            .init(
              name: "seconds",
              typeDescription: .simple(name: "Int"),
              modifiers: [.internal, .instance],
              paradigm: .undefinedConstant),
            .init(
              name: "hours",
              typeDescription: .simple(name: "Double"),
              modifiers: [.internal, .instance],
              paradigm: .undefinedConstant),
            .init(
              name: "years",
              typeDescription: .simple(name: "Double"),
              modifiers: [.internal, .instance],
              paradigm: .undefinedConstant)
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
              typeDescription: .simple(name: "String"),
              modifiers: [.public, .static],
              paradigm: .definedVariable("\"Hello, World\""))
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
              typeDescription: .simple(name: "String"),
              modifiers: [.public, .static],
              paradigm: .definedVariable("\"Hello, World\""))
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
              typeDescription: .simple(name: "String"),
              modifiers: [.private, .static],
              paradigm: .definedVariable("\"Hello, World\""))
          ]
        }
      }

      context("when there is a open private(set) property") {
        let content = """
        open private(set) var thing: String = "Hello, World"
        """

        it("detects the property") {
          try sut.walkContent(content)
          expect(sut.properties) == [
            PropertyInfo(
              name: "thing",
              typeDescription: .simple(name: "String"),
              modifiers: [.open, .privateSet, .instance],
              paradigm: .definedVariable("\"Hello, World\""))
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
              typeDescription: .simple(name: "String"),
              modifiers: [.public, .internalSet, .instance],
              paradigm: .definedVariable("\"Hello, World\""))
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
              typeDescription: .simple(name: "String"),
              modifiers: [.publicSet, .internal, .instance],
              paradigm: .definedVariable("\"Hello, World\""))
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
              typeDescription: .simple(name: "String"),
              modifiers: [.fileprivate, .static],
              paradigm: .definedVariable("\"Hello, World\""))
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
              typeDescription: nil,
              modifiers: [.private, .static],
              paradigm: .definedVariable("\"Hello, World\""))
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
              typeDescription: nil,
              modifiers: [.public, .instance],
              paradigm: .definedVariable("\"Hello, World\""))
          ]
        }
      }

      context("when the property is an undefined constant property") {
        let content = """
        let foo: Foo
        """

        it("has expected paradigm") {
          try sut.walkContent(content)
          expect(sut.properties.first?.paradigm).to(equal(.undefinedConstant))
        }
      }

      context("when the property is a defined constant property") {

        it("has expected paradigm") {
          let content = """
          let foo = Foo()
          """

          try sut.walkContent(content)
          expect(sut.properties.first?.paradigm).to(equal(.definedConstant("Foo()")))
        }

        context("that is malformed") {
          let content = """
          let foo = Foo() = Foo()
          """

          it("creates a paradigm without asserting") {
            try sut.walkContent(content)
            expect(sut.properties.first?.paradigm).to(equal(.definedConstant("Foo() = Foo()")))
          }
        }
      }

      context("when the property is an undefined variable property") {
        let content = """
        var foo: Foo
        """

        it("has expected paradigm") {
          try sut.walkContent(content)
          expect(sut.properties.first?.paradigm).to(equal(.undefinedVariable))
        }
      }

      context("when the property is a defined variable property") {
        it("has expected paradigm") {
          let content = """
          var foo = Foo()
          """

          try sut.walkContent(content)
          expect(sut.properties.first?.paradigm).to(equal(.definedVariable("Foo()")))
        }

        context("initialized with a closure") {
          let content = """
          var foo = { Foo() }()
          """

          it("has expected paradigm") {
            try sut.walkContent(content)
            expect(sut.properties.first?.paradigm).to(equal(.definedVariable("{ Foo() }()")))
          }
        }
      }

      context("when the property is a computed variable property") {
        let content = """
        var foo { Foo() }
        """

        it("has expected paradigm") {
          try sut.walkContent(content)
          expect(sut.properties.first?.paradigm).to(equal(.computedVariable("Foo()")))
        }
      }

      context("when the property is part of a protocol definition") {
        var protocolVisitor: TestProtocolVisitor!

        beforeEach {
          protocolVisitor = TestProtocolVisitor(propertyVisitor: sut)
        }

        context("and is only gettable") {
          let content = """
          var foo: Foo { get }
          """

          fit("has expected paradigm") {
            try protocolVisitor.walkContent(content)
            expect(sut.properties.first?.paradigm).to(equal(.protocolGetter))
          }
        }

        context("and is gettable and settable") {
          let content = """
          var foo: Foo { get set }
          """

          // We will figure out how to implement this when we need it.
          it("is not found") {
            try protocolVisitor.walkContent(content)
            expect(sut.properties).to(beEmpty())
          }
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
              typeDescription: .simple(name: "Int"),
              modifiers: [.internal, .instance],
              paradigm: .undefinedConstant)
          ]
          expect(sut.properties).to(contain(expected))
        }

        it("does not detect properties within type declaration") {
          try sut.walkContent(content)
          expect(sut.properties.map(\.name)).notTo(contain("timestamp"))
        }
      }

    }
  }
}

// MARK: - TestProtocolVisitor

private final class TestProtocolVisitor: SyntaxVisitor {

  init(propertyVisitor: PropertyVisitor) {
    self.propertyVisitor = propertyVisitor
  }

  override func visit(_ node: VariableDeclSyntax) -> SyntaxVisitorContinueKind {
    propertyVisitor.walk(node)
    return .skipChildren
  }

  private let propertyVisitor: PropertyVisitor
}
