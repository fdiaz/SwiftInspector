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
    }

    describe("visit(_:)") {
      context("a function with a return value") {
        beforeEach {
          let content = """
            func greet(person: String) -> String {
                let greeting = "Hello, " + person + "!"
                return greeting
            }
            """

          try? self.sut.walkContent(content)
        }

        it("finds the function name") {
          expect(self.sut.functionDeclarations.first?.name) == "greet"
        }
        it("finds the function parameter") {
          expect(self.sut.functionDeclarations.first?.arguments?.first?.argumentLabelName) == "person"
          expect(self.sut.functionDeclarations.first?.arguments?.first?.type) == .simple(name: "String")
        }
        it("finds the return type") {
          expect(self.sut.functionDeclarations.first?.returnType) == TypeDescription.simple(name: "String")
        }
      }

      context("a function without a return value") {
        beforeEach {
          let content = """
            func printWithoutCounting(string: String) {
                let _ = printAndCount(string: string)
            }
            """

          try? self.sut.walkContent(content)
        }

        it("finds the function name") {
          expect(self.sut.functionDeclarations.first?.name) == "printWithoutCounting"
        }
        it("finds the function parameter") {
          expect(self.sut.functionDeclarations.first?.arguments?.first?.argumentLabelName) == "string"
          expect(self.sut.functionDeclarations.first?.arguments?.first?.type) == .simple(name: "String")
        }
        it("sets the return type as nil") {
          expect(self.sut.functionDeclarations.first?.returnType).to(beNil())
        }
      }

      context("a function with multiple return values") {
        beforeEach {
          let content = """
            func minMax(array: [Int]) -> (min: Int, max: Int) {
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

        it("finds the function name") {
          expect(self.sut.functionDeclarations.first?.name) == "minMax"
        }
        it("finds the function parameter") {
          expect(self.sut.functionDeclarations.first?.arguments?.first?.argumentLabelName) == "array"
          expect(self.sut.functionDeclarations.first?.arguments?.first?.type) == .array(element: .simple(name: "Int"))
        }
        it("finds the tuple return value") {
          expect(self.sut.functionDeclarations.first?.returnType) == .tuple([.simple(name: "Int"), .simple(name: "Int")])
        }

      }

      context("multiple functions") {
        beforeEach {
          let content = """
            func minMax(array: [Int]) -> (min: Int, max: Int) {
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

            func printWithoutCounting(string: String) {
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
          expect(firstFunction?.name) == "minMax"
          expect(firstFunction?.arguments?.first?.argumentLabelName) == "array"
          expect(firstFunction?.arguments?.first?.type) == .array(element: .simple(name: "Int"))
          expect(firstFunction?.returnType) == .tuple([.simple(name: "Int"), .simple(name: "Int")])
        }
        it("finds the last function") {
          let lastFunction = self.sut.functionDeclarations.last
          expect(lastFunction?.name) == "printWithoutCounting"
          expect(lastFunction?.arguments?.first?.argumentLabelName) == "string"
          expect(lastFunction?.arguments?.first?.type) == .simple(name: "String")
          expect(lastFunction?.returnType).to(beNil())
        }
      }

      context("function with no external parameter label") {
        beforeEach {
          let content = """
            func print(_ string: String) {
                let _ = printAndCount(string: string)
            }
            """

          try? self.sut.walkContent(content)
        }

        it("finds the parameter label") {
          expect(self.sut.functionDeclarations.first?.arguments?.first?.argumentLabelName) == "_"
        }
        it("calculates the selectorName") {
          expect(self.sut.functionDeclarations.first?.selectorName) == "print(_:)"
        }
      }

      context("function with custom external parameter label") {
        beforeEach {
          let content = """
            func append(argumentLabelName parameterName: String) {
              // ...
            }
            """

          try? self.sut.walkContent(content)
        }

        it("finds the parameter label") {
          expect(self.sut.functionDeclarations.first?.arguments?.first?.argumentLabelName) == "argumentLabelName"
        }
        it("calculates the selectorName") {
          expect(self.sut.functionDeclarations.first?.selectorName) == "append(argumentLabelName:)"
        }
      }

      context("function with multiple parameters") {
        beforeEach {
          let content = """
            func append(argumentLabelName parameterName: String, type: TypeDescription) {
              // ...
            }
            """

          try? self.sut.walkContent(content)
        }

        it("finds the correct number of parameters") {
          expect(self.sut.functionDeclarations.first?.arguments?.count) == 2
        }
        it("finds the parameter labels") {
          expect(self.sut.functionDeclarations.first?.arguments?.first?.argumentLabelName) == "argumentLabelName"
          expect(self.sut.functionDeclarations.first?.arguments?.last?.argumentLabelName) == "type"
        }
        it("calculates the selectorName") {
          expect(self.sut.functionDeclarations.first?.selectorName) == "append(argumentLabelName:type:)"
        }
      }
    }
  }
}
