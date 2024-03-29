import Foundation
import Nimble
import Quick
import SwiftInspectorTestHelpers
import SwiftInspectorVisitors

final class FunctionDeclarationVisitorSpec: QuickSpec {
  private var sut: FunctionDeclarationVisitor!

  override func spec() {
    beforeEach {
      self.sut = FunctionDeclarationVisitor()
      AssertionFailure.postNotification = true
    }

    describe("visit(_:)") {
      context("a function with a return value") {
        beforeEach {
          let content = """
            fileprivate func greet(person: String) -> String {
                let greeting = "Hello, " + person + "!"
                return greeting
            }
            """

          try? self.sut.walkContent(content)
        }

        it("finds the modifiers") {
          expect(self.sut.functionDeclarations.first?.modifiers) == Modifiers.fileprivate
        }
        it("finds the function name") {
          expect(self.sut.functionDeclarations.first?.name) == "greet"
        }
        it("finds the function parameter") {
          expect(self.sut.functionDeclarations.first?.parameters?.first?.argumentLabelName) == "person"
          expect(self.sut.functionDeclarations.first?.parameters?.first?.parameterName) == "person"
          expect(self.sut.functionDeclarations.first?.parameters?.first?.type) == .simple(name: "String")
        }
        it("finds the return type") {
          expect(self.sut.functionDeclarations.first?.returnType) == TypeDescription.simple(name: "String")
        }
      }

      context("a function without a return value and without modifiers") {
        beforeEach {
          let content = """
            func printWithoutCounting(string: String) {
                let _ = printAndCount(string: string)
            }
            """

          try? self.sut.walkContent(content)
        }

        it("finds no modifiers") {
          expect(self.sut.functionDeclarations.first?.modifiers) == []
        }
        it("finds the function name") {
          expect(self.sut.functionDeclarations.first?.name) == "printWithoutCounting"
        }
        it("finds the function parameter") {
          expect(self.sut.functionDeclarations.first?.parameters?.first?.argumentLabelName) == "string"
          expect(self.sut.functionDeclarations.first?.parameters?.first?.parameterName) == "string"
          expect(self.sut.functionDeclarations.first?.parameters?.first?.type) == .simple(name: "String")
        }
        it("sets the return type as nil") {
          expect(self.sut.functionDeclarations.first?.returnType).to(beNil())
        }
      }

      context("a function with multiple return values") {
        beforeEach {
          let content = """
            internal func minMax(array: [Int]) -> (min: Int, max: Int) {
                var currentMin = array[0]
                var currentMax = array[0]
                for value in array[1..<array.count] {
                    if value < currentMin {
                        currentMin = value
                    } else if value > currentMax {
                        currentMax = value
                    }
                }
                return (currentMin, currentMax)
            }
            """

          try? self.sut.walkContent(content)
        }

        it("finds the modifiers") {
          expect(self.sut.functionDeclarations.first?.modifiers) == Modifiers.internal
        }
        it("finds the function name") {
          expect(self.sut.functionDeclarations.first?.name) == "minMax"
        }
        it("finds the function parameter") {
          expect(self.sut.functionDeclarations.first?.parameters?.first?.argumentLabelName) == "array"
          expect(self.sut.functionDeclarations.first?.parameters?.first?.parameterName) == "array"
          expect(self.sut.functionDeclarations.first?.parameters?.first?.type) == .array(element: .simple(name: "Int"))
        }
        it("finds the tuple return value") {
          expect(self.sut.functionDeclarations.first?.returnType) == .tuple([.simple(name: "Int"), .simple(name: "Int")])
        }

      }

      context("multiple functions") {
        beforeEach {
          let content = """
            public func minMax(array: [Int]) -> (min: Int, max: Int) {
                var currentMin = array[0]
                var currentMax = array[0]
                for value in array[1..<array.count] {
                    if value < currentMin {
                        currentMin = value
                    } else if value > currentMax {
                        currentMax = value
                    }
                }
                return (currentMin, currentMax)
            }

            private static func printWithoutCounting(string: String) {
                let _ = printAndCount(string: string)
            }
            """

          try? self.sut.walkContent(content)
        }

        it("finds the correct number of functions") {
          expect(self.sut.functionDeclarations.count) == 2
        }
        it("finds the first function") {
          let firstFunction = self.sut.functionDeclarations.first
          expect(firstFunction?.modifiers) == Modifiers.public
          expect(firstFunction?.name) == "minMax"
          expect(firstFunction?.parameters?.first?.argumentLabelName) == "array"
          expect(firstFunction?.parameters?.first?.type) == .array(element: .simple(name: "Int"))
          expect(firstFunction?.returnType) == .tuple([.simple(name: "Int"), .simple(name: "Int")])
        }
        it("finds the last function") {
          let lastFunction = self.sut.functionDeclarations.last
          expect(lastFunction?.modifiers) == [.private, .static]
          expect(lastFunction?.name) == "printWithoutCounting"
          expect(lastFunction?.parameters?.first?.argumentLabelName) == "string"
          expect(lastFunction?.parameters?.first?.type) == .simple(name: "String")
          expect(lastFunction?.returnType).to(beNil())
        }
      }

      context("function with no parameters") {
        beforeEach {
          let content = """
            func helloWorld() {
                print("Hello, world!")
            }
            """

          try? self.sut.walkContent(content)
        }

        it("finds no parameters") {
          expect(self.sut.functionDeclarations.first?.parameters).to(beNil())
        }
      }

      context("function with empty argument label") {
        beforeEach {
          let content = """
            func print(_ string: String) {
                let _ = printAndCount(string: string)
            }
            """

          try? self.sut.walkContent(content)
        }

        it("finds the argument label") {
          expect(self.sut.functionDeclarations.first?.parameters?.first?.argumentLabelName) == "_"
        }
        it("finds the parameter name") {
          expect(self.sut.functionDeclarations.first?.parameters?.first?.parameterName) == "string"
        }
        it("calculates the selectorName") {
          expect(self.sut.functionDeclarations.first?.selectorName) == "print(_:)"
        }
      }

      context("function with an argument label that differs from the parameter name") {
        beforeEach {
          let content = """
            func append(argumentLabelName parameterName: String) {
              // ...
            }
            """

          try? self.sut.walkContent(content)
        }

        it("finds the argument label") {
          expect(self.sut.functionDeclarations.first?.parameters?.first?.argumentLabelName) == "argumentLabelName"
        }
        it("calculates the selectorName") {
          expect(self.sut.functionDeclarations.first?.selectorName) == "append(argumentLabelName:)"
        }
        it("finds the parameter name") {
          expect(self.sut.functionDeclarations.first?.parameters?.first?.parameterName) == "parameterName"
        }
      }

      context("function with multiple parameters") {
        beforeEach {
          let content = """
            func append(argumentLabelName parameterName: String, type secondParameterName: TypeDescription) {
              // ...
            }
            """

          try? self.sut.walkContent(content)
        }

        it("finds the correct number of parameters") {
          expect(self.sut.functionDeclarations.first?.parameters?.count) == 2
        }
        it("finds the argument labels") {
          expect(self.sut.functionDeclarations.first?.parameters?.first?.argumentLabelName) == "argumentLabelName"
          expect(self.sut.functionDeclarations.first?.parameters?.last?.argumentLabelName) == "type"
        }
        it("finds the parameter names") {
          expect(self.sut.functionDeclarations.first?.parameters?.first?.parameterName) == "parameterName"
          expect(self.sut.functionDeclarations.first?.parameters?.last?.parameterName) == "secondParameterName"
        }
        it("calculates the selectorName") {
          expect(self.sut.functionDeclarations.first?.selectorName) == "append(argumentLabelName:type:)"
        }
      }

      context("visiting a code block with a class declaration") {
        it("asserts") {
          let content = """
            final class Test {
              func test() {}
            }
            """

          // The FunctionDeclarationVisitor is only meant to be used over a single function declaration.
          // Using a FunctionDeclarationVisitor over a block that has a class declaration
          // is API misuse.
          expect(try self.sut.walkContent(content)).to(postNotifications(equal([AssertionFailure.notification])))
        }
      }

      context("visiting a code block with a struct declaration") {
        it("asserts") {
          let content = """
            struct Test {
              func test() {}
            }
            """

          // The FunctionDeclarationVisitor is only meant to be used over a single function declaration.
          // Using a FunctionDeclarationVisitor over a block that has a struct declaration
          // is API misuse.
          expect(try self.sut.walkContent(content)).to(postNotifications(equal([AssertionFailure.notification])))
        }
      }

      context("visiting a code block with a enum declaration") {
        it("asserts") {
          let content = """
            enum Test {
              func test() {}
            }
            """

          // The FunctionDeclarationVisitor is only meant to be used over a single function declaration.
          // Using a FunctionDeclarationVisitor over a block that has an enum declaration
          // is API misuse.
          expect(try self.sut.walkContent(content)).to(postNotifications(equal([AssertionFailure.notification])))
        }
      }

      context("visiting a code block with a protocol declaration") {
        it("asserts") {
          let content = """
            protocol Test {
              func test()
            }
            """

          // The FunctionDeclarationVisitor is only meant to be used over a single function declaration.
          // Using a FunctionDeclarationVisitor over a block that has a protocol declaration
          // is API misuse.
          expect(try self.sut.walkContent(content)).to(postNotifications(equal([AssertionFailure.notification])))
        }
      }

      context("visiting a code block with an extension declaration") {
        it("asserts") {
          let content = """
            extension Test {
              func test()
            }
            """

          // The FunctionDeclarationVisitor is only meant to be used over a single function declaration.
          // Using a FunctionDeclarationVisitor over a block that has an extension declaration
          // is API misuse.
          expect(try self.sut.walkContent(content)).to(postNotifications(equal([AssertionFailure.notification])))
        }
      }

    }
  }
}
