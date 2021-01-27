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

@testable import SwiftInspectorAnalyzers

final class ImportsAnalyzerSpec: QuickSpec {
  private var fileURL: URL!

  override func spec() {
    afterEach {
      guard let fileURL = self.fileURL else {
        return
      }
      try? Temporary.removeItem(at: fileURL)
    }

    describe("analyze(fileURL:)") {
      context("when there is no import statement") {
        let content = """
                      public final class Some {
                      }
                      """
        self.fileURL = try? Temporary.makeFile(content: content)

        it("returns an empty array") {
          let sut = ImportsAnalyzer()
          let result = try? sut.analyze(fileURL: self.fileURL)

          expect(result).to(beEmpty())
        }
      }

      context("with a simple import statements") {
        var sut: [ImportStatement]? = []
        beforeEach {
          let content = """
                        import SomeModule

                        public final class Some {
                        }
                        """
          self.fileURL = try? Temporary.makeFile(content: content)
          sut = try? ImportsAnalyzer().analyze(fileURL: self.fileURL)
        }

        it("returns the appropriate main module name") {
          expect(sut?.first?.mainModule) == "SomeModule"
        }

        it("returns an empty String for the submodule name") {
          expect(sut?.first?.submodule) == ""
        }

        it("returns an empty String for the kind") {
          expect(sut?.first?.kind) == ""
        }

      }

      context("with an  import statement with an attribute") {
        var sut: [ImportStatement]? = []
        beforeEach {
          let content = """
                        @_export import SomeModule

                        public final class Some {}
                        """
          self.fileURL = try? Temporary.makeFile(content: content)
          sut = try? ImportsAnalyzer().analyze(fileURL: self.fileURL)
        }

        it("returns the appropriate attribute name") {
          expect(sut?.first?.attribute) == "_export"
        }
      }

      context("with an import statement with a submodule") {
        var sut: [ImportStatement]? = []
        beforeEach {
          let content = """
                        import SomeModule.Submodule

                        public final class Some {
                        }
                        """
          self.fileURL = try? Temporary.makeFile(content: content)
          sut = try? ImportsAnalyzer().analyze(fileURL: self.fileURL)
        }

        it("returns the appropriate main module name") {
          expect(sut?.first?.mainModule) == "SomeModule"
        }

        it("returns the appropriate submodule name") {
          expect(sut?.first?.submodule) == "Submodule"
        }

        it("returns the appropriate kind") {
          expect(sut?.first?.kind) == ""
        }

      }

      context("with an import statement with a kind and a submodule") {
        var sut: [ImportStatement]? = []
        beforeEach {
          let content = """
                        import struct SomeModule.Submodule

                        public final class Some {
                        }
                        """
          self.fileURL = try? Temporary.makeFile(content: content)
          sut = try? ImportsAnalyzer().analyze(fileURL: self.fileURL)
        }

        it("returns the appropriate main module name") {
          expect(sut?.first?.mainModule) == "SomeModule"
        }

        it("returns the appropriate submodule name") {
          expect(sut?.first?.submodule) == "Submodule"
        }

        it("returns the appropriate kind") {
          expect(sut?.first?.kind) == "struct"
        }

      }

      context("with multiple import statements with a kind and a submodule") {
        var sut: [ImportStatement]? = []
        beforeEach {
          let content = """
                        import struct SomeModule.Submodule
                        import class Another.AnotherSubmodule

                        public final class Some {
                        }
                        """
          self.fileURL = try? Temporary.makeFile(content: content)
          sut = try? ImportsAnalyzer().analyze(fileURL: self.fileURL)
        }

        it("returns the appropriate main module name for all imports") {
          expect(sut?.first?.mainModule) == "SomeModule"
          expect(sut?.last?.mainModule) == "Another"
        }

        it("returns the appropriate submodule name for all imports") {
          expect(sut?.first?.submodule) == "Submodule"
          expect(sut?.last?.submodule) == "AnotherSubmodule"
        }

        it("returns the appropriate kind for all imports") {
          expect(sut?.first?.kind) == "struct"
          expect(sut?.last?.kind) == "class"
        }

      }

    }

  }
}
