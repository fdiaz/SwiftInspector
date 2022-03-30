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
        it("finds the return type") {
          expect(self.sut.functionDeclarations.first?.returnType) == TypeDescription.simple(name: "String")
        }
      }

      context("a function with a return value") {
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
        it("sets the return type as nil") {
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

        it("finds the correct amount of functions") {
          expect(self.sut.functionDeclarations.count) == 2
        }
        it("finds the first function") {
          expect(self.sut.functionDeclarations.first?.name) == "minMax"
          expect(self.sut.functionDeclarations.first?.returnType) == .tuple([.simple(name: "Int"), .simple(name: "Int")])
        }
        it("finds the last function") {
          expect(self.sut.functionDeclarations.last?.name) == "printWithoutCounting"
          expect(self.sut.functionDeclarations.last?.returnType).to(beNil())
        }
      }
      
    }
  }
}
