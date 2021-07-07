// Created by Francisco Diaz on 10/16/19.
//
// Copyright (c) 2020 Francisco Diaz
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

final class ImportVisitorSpec: QuickSpec {
  private var sut = ImportVisitor()

  override func spec() {
    beforeEach {
      self.sut = ImportVisitor()
    }

    describe("visit") {
      context("when there is no import statement") {
        let content = """
                      public final class Some {
                      }
                      """

        it("returns an empty array") {
          try self.sut.walkContent(content)

          expect(self.sut.imports).to(beEmpty())
        }
      }

      context("with a simple import statements") {
        beforeEach {
          let content = """
                        import SomeModule

                        public final class Some {
                        }
                        """
          try? self.sut.walkContent(content)
        }

        it("returns the appropriate main module name") {
          expect(self.sut.imports.first?.mainModule) == "SomeModule"
        }

        it("returns an empty String for the submodule name") {
          expect(self.sut.imports.first?.submodule) == ""
        }

        it("returns an empty String for the kind") {
          expect(self.sut.imports.first?.kind) == ""
        }

      }

      context("with an import statement with an attribute") {
        beforeEach {
          let content = """
                        @_exported import SomeModule

                        public final protocol Some {}
                        """
          try? self.sut.walkContent(content)
        }

        it("returns the appropriate attribute name") {
          expect(self.sut.imports.first?.attribute) == "_exported"
        }
      }

      context("with an import statement with a submodule") {
        beforeEach {
          let content = """
                        import SomeModule.Submodule

                        public final struct Some {}
                        """
          try? self.sut.walkContent(content)
        }

        it("returns the appropriate main module name") {
          expect(self.sut.imports.first?.mainModule) == "SomeModule"
        }

        it("returns the appropriate submodule name") {
          expect(self.sut.imports.first?.submodule) == "Submodule"
        }

        it("returns the appropriate kind") {
          expect(self.sut.imports.first?.kind) == ""
        }

      }

      context("with an import statement with a kind and a submodule") {
        beforeEach {
          let content = """
                        import struct SomeModule.Submodule

                        public final enum Some {}
                        """
          try? self.sut.walkContent(content)
        }

        it("returns the appropriate main module name") {
          expect(self.sut.imports.first?.mainModule) == "SomeModule"
        }

        it("returns the appropriate submodule name") {
          expect(self.sut.imports.first?.submodule) == "Submodule"
        }

        it("returns the appropriate kind") {
          expect(self.sut.imports.first?.kind) == "struct"
        }

      }

      context("with multiple import statements with a kind and a submodule") {
        beforeEach {
          let content = """
                        import struct SomeModule.Submodule
                        import class Another.AnotherSubmodule

                        public final class Some {}
                        """
          try? self.sut.walkContent(content)
        }

        it("returns the appropriate main module name for all imports") {
          expect(self.sut.imports.first?.mainModule) == "SomeModule"
          expect(self.sut.imports.last?.mainModule) == "Another"
        }

        it("returns the appropriate submodule name for all imports") {
          expect(self.sut.imports.first?.submodule) == "Submodule"
          expect(self.sut.imports.last?.submodule) == "AnotherSubmodule"
        }

        it("returns the appropriate kind for all imports") {
          expect(self.sut.imports.first?.kind) == "struct"
          expect(self.sut.imports.last?.kind) == "class"
        }

      }

    }

  }
}
