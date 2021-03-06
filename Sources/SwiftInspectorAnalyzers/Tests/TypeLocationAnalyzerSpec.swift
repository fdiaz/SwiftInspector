// Created by Michael Bachand on 3/28/20.
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

@testable import SwiftInspectorAnalyzers

final class TypeLocationAnalyzerSpec: QuickSpec {

  override func spec() {
    var fileURL: URL!

    afterEach {
      guard let fileURL = fileURL else {
        return
      }
      try? Temporary.removeItem(at: fileURL)
    }

    describe("analyze(fileURL:)") {
      context("the type is not present") {
        let content =
        """
        import Foundation
        """
        fileURL = try? Temporary.makeFile(content: content)

        it("returns empty array") {
          let sut = TypeLocationAnalyzer(typeName: "Foo")
          let result = try? sut.analyze(fileURL: fileURL)
          expect(result).to(beEmpty())
        }
      }

      context("struct is present") {
        beforeEach {
          let content =
          """
          struct Foo { }
          """
          fileURL = try? Temporary.makeFile(content: content)
        }

        context("name matches") {
          it("returns type location") {
            let sut = TypeLocationAnalyzer(typeName: "Foo")
            let result = try? sut.analyze(fileURL: fileURL)
            expect(result).notTo(beEmpty())
          }
        }

        context("name does not match") {
          it("returns empty array") {
            let sut = TypeLocationAnalyzer(typeName: "Bar")
            let result = try? sut.analyze(fileURL: fileURL)
            expect(result).to(beEmpty())
          }
        }
      }

      context("enum is present") {
        beforeEach {
          let content =
          """
          enum Foo { }
          """
          fileURL = try? Temporary.makeFile(content: content)

        }

        context("name matches") {
          it("returns type location") {
            let sut = TypeLocationAnalyzer(typeName: "Foo")
            let result = try? sut.analyze(fileURL: fileURL)
            expect(result).notTo(beEmpty())
          }
        }

        context("name does not match") {
          it("returns empty array") {
            let sut = TypeLocationAnalyzer(typeName: "Bar")
            let result = try? sut.analyze(fileURL: fileURL)
            expect(result).to(beEmpty())
          }
        }
      }

      context("class is present") {
        beforeEach {
          let content =
          """
          class Foo { }
          """
          fileURL = try? Temporary.makeFile(content: content)
        }

        context("name matches") {
          it("returns type location") {
            let sut = TypeLocationAnalyzer(typeName: "Foo")
            let result = try? sut.analyze(fileURL: fileURL)
            expect(result).notTo(beEmpty())
          }
        }

        context("name does not match") {
          it("returns empty array") {
            let sut = TypeLocationAnalyzer(typeName: "Bar")
            let result = try? sut.analyze(fileURL: fileURL)
            expect(result).to(beEmpty())
          }
        }
      }

      context("protocol is present") {
        beforeEach {
          let content =
          """
          protocol Foo { }
          """
          fileURL = try? Temporary.makeFile(content: content)
        }

        context("name matches") {
          it("returns type location") {
            let sut = TypeLocationAnalyzer(typeName: "Foo")
            let result = try? sut.analyze(fileURL: fileURL)
            expect(result).notTo(beEmpty())
          }
        }

        context("name does not match") {
          it("returns empty array") {
            let sut = TypeLocationAnalyzer(typeName: "Bar")
            let result = try? sut.analyze(fileURL: fileURL)
            expect(result).to(beEmpty())
          }
        }
      }

      context("type is one line") {
        context("which is the first line of file") {
          beforeEach {
            let content =
            """
            enum Foo { }
            """
            fileURL = try? Temporary.makeFile(content: content)
          }

          it("returns correct start and end indices") {
            let sut = TypeLocationAnalyzer(typeName: "Foo")
            let result = try? sut.analyze(fileURL: fileURL)
            let typeLocation = result?.first
            expect(typeLocation?.indexOfStartingLine) == 0
            expect(typeLocation?.indexOfEndingLine) == 0
          }
        }

        context("which is not the first line of file") {
          beforeEach {
            let content =
            """
            import Foundation

            enum Foo { }
            """
            fileURL = try? Temporary.makeFile(content: content)
          }

          it("returns correct start and end indices") {
            let sut = TypeLocationAnalyzer(typeName: "Foo")
            let result = try? sut.analyze(fileURL: fileURL)
            let typeLocation = result?.first
            expect(typeLocation?.indexOfStartingLine) == 2
            expect(typeLocation?.indexOfEndingLine) == 2
          }
        }
      }

      context("type spans multiple lines") {
        context("starting on the first line of the file") {
          beforeEach {
            let content =
            """
            struct Foo {
              let myProperty: String
            }
            """
            fileURL = try? Temporary.makeFile(content: content)
          }

          it("returns correct start and end indices") {
            let sut = TypeLocationAnalyzer(typeName: "Foo")
            let result = try? sut.analyze(fileURL: fileURL)
            let typeLocation = result?.first
            expect(typeLocation?.indexOfStartingLine) == 0
            expect(typeLocation?.indexOfEndingLine) == 2
          }
        }

        context("starting on a line of the file that is not the first") {
          beforeEach {
            let content =
            """
            import Foundation

            struct Foo {
              let myProperty: String
            }
            """
            fileURL = try? Temporary.makeFile(content: content)
          }

          it("returns correct start and end indices") {
            let sut = TypeLocationAnalyzer(typeName: "Foo")
            let result = try? sut.analyze(fileURL: fileURL)
            let typeLocation = result?.first
            expect(typeLocation?.indexOfStartingLine) == 2
            expect(typeLocation?.indexOfEndingLine) == 4
          }
        }

        context("contains another single line type") {
          beforeEach {
            let content =
            """
            import Foundation

            struct Foo {
              let myProperty: String

              enum Bar { }
            }
            """
            fileURL = try? Temporary.makeFile(content: content)
          }

          it("returns correct start and end indices") {
            let sut = TypeLocationAnalyzer(typeName: "Foo")
            let result = try? sut.analyze(fileURL: fileURL)
            let typeLocation = result?.first
            expect(typeLocation?.indexOfStartingLine) == 2
            expect(typeLocation?.indexOfEndingLine) == 6
          }
        }

        context("contains another type that spans multiple lines") {
          beforeEach {
            let content =
            """
            import Foundation

            struct Foo {
              let myProperty: String

              enum Bar {
                case myCase
              }
            }
            """
            fileURL = try? Temporary.makeFile(content: content)
          }

          it("returns correct start and end indices") {
            let sut = TypeLocationAnalyzer(typeName: "Foo")
            let result = try? sut.analyze(fileURL: fileURL)
            let typeLocation = result?.first
            expect(typeLocation?.indexOfStartingLine) == 2
            expect(typeLocation?.indexOfEndingLine) == 8
          }
        }
      }

      context("when multiple types with the same name exist") {
        beforeEach {
          let content =
          """
          struct Foo { }

          class Bar {
            enum Foo { }
          }
          """
          fileURL = try? Temporary.makeFile(content: content)
        }

        it("returns correct start and end indices") {
          let sut = TypeLocationAnalyzer(typeName: "Foo")
          let result = try? sut.analyze(fileURL: fileURL)
          expect(result?.count).to(equal(2))
          expect(result?.first?.indexOfStartingLine) == 0
          expect(result?.first?.indexOfEndingLine) == 0
          expect(result?.last?.indexOfStartingLine) == 3
          expect(result?.last?.indexOfEndingLine) == 3
        }
      }

      context("when the type has a modifier") {
        beforeEach {
          let content =
          """

          final class Foo {
          }
          """
          fileURL = try? Temporary.makeFile(content: content)
        }

        it("returns correct start and end indices") {
          let sut = TypeLocationAnalyzer(typeName: "Foo")
          let result = try? sut.analyze(fileURL: fileURL)
          let typeLocation = result?.first
          expect(typeLocation?.indexOfStartingLine) == 1
          expect(typeLocation?.indexOfEndingLine) == 2
        }
      }

      context("when the type has modifiers on multiple lines") {
        beforeEach {
          let content =
          """

          public
          final
          class Foo {
          }
          """
          fileURL = try? Temporary.makeFile(content: content)
        }

        it("returns correct start and end indices") {
          let sut = TypeLocationAnalyzer(typeName: "Foo")
          let result = try? sut.analyze(fileURL: fileURL)
          let typeLocation = result?.first
          expect(typeLocation?.indexOfStartingLine) == 1
          expect(typeLocation?.indexOfEndingLine) == 4
        }
      }

      context("when the type has an attribute") {
        beforeEach {
          let content =
          """
          import Foundation

          @objc class Foo: NSObject {
          }
          """
          fileURL = try? Temporary.makeFile(content: content)
        }

        it("returns correct start and end indices") {
          let sut = TypeLocationAnalyzer(typeName: "Foo")
          let result = try? sut.analyze(fileURL: fileURL)
          let typeLocation = result?.first
          expect(typeLocation?.indexOfStartingLine) == 2
          expect(typeLocation?.indexOfEndingLine) == 3
        }
      }

      context("when the type has an attribute and modifiers") {
        beforeEach {
          let content =
          """
          import Foundation

          @objc
          public final class Foo: NSObject {
          }
          """
          fileURL = try? Temporary.makeFile(content: content)
        }

        it("returns correct start and end indices") {
          let sut = TypeLocationAnalyzer(typeName: "Foo")
          let result = try? sut.analyze(fileURL: fileURL)
          let typeLocation = result?.first
          expect(typeLocation?.indexOfStartingLine) == 2
          expect(typeLocation?.indexOfEndingLine) == 4
        }
      }
    }
  }
}
