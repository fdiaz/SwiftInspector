// Created by Francisco Diaz on 10/16/19.
// Copyright © 2019 Airbnb Inc. All rights reserved.

import Nimble
import Quick
import Foundation

@testable import SwiftInspectorKit

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
        self.fileURL = try? Temporary.makeSwiftFile(content: content, name: "ABC")

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
          self.fileURL = try? Temporary.makeSwiftFile(content: content, name: "ABC")
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

      context("with an import statement with a submodule") {
        var sut: [ImportStatement]? = []
        beforeEach {
          let content = """
                        import SomeModule.Submodule

                        public final class Some {
                        }
                        """
          self.fileURL = try? Temporary.makeSwiftFile(content: content, name: "ABC")
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
          self.fileURL = try? Temporary.makeSwiftFile(content: content, name: "ABC")
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
          self.fileURL = try? Temporary.makeSwiftFile(content: content, name: "ABC")
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
