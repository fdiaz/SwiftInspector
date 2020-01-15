// Created by Francisco Diaz on 10/14/19.
// Copyright © 2019 Airbnb Inc. All rights reserved.

import Nimble
import Quick
import Foundation

@testable import SwiftInspectorKit

final class TypeConformanceAnalyzerSpec: QuickSpec {
  private var fileURL: URL!

  override func spec() {
    afterEach {
      guard let fileURL = self.fileURL else {
        return
      }
      try? Temporary.removeItem(at: fileURL)
    }

    describe("analyze(fileURL:)") {

      context("when a type conforms to a protocol") {
        it("returns the correct filename") {
          let content = """
          protocol Some {}

          class Another: Some {}
          """

          self.fileURL = try? Temporary.makeSwiftFile(content: content, name: "AFile")

          let sut = TypeConformanceAnalyzer(typeName: "Some")
          let result = try? sut.analyze(fileURL: self.fileURL)

          expect(result?.lastPathComponent) == "AFile.swift"
        }

        context("with only one conformance") {
          it("conforms") {
            let content = """
            protocol Some {}

            class Another: Some {}
            """

            self.fileURL = try? Temporary.makeSwiftFile(content: content)

            let sut = TypeConformanceAnalyzer(typeName: "Some")
            let result = try? sut.analyze(fileURL: self.fileURL)

            expect(result?.doesConform) == true
          }

          context("when the type has multiple conformances") {
            it("conforms") {
              let content = """
              protocol Foo {}
              protocol Bar {}

              class Another: Foo, Bar {}

              class Second: Foo {}
              """

              self.fileURL = try? Temporary.makeSwiftFile(content: content)

              let sut = TypeConformanceAnalyzer(typeName: "Bar")
              let result = try? sut.analyze(fileURL: self.fileURL)

              expect(result?.doesConform) == true
            }
          }

          context("when the types conform in a different line") {
            it("conforms") {
              let content = """
              protocol A {}
              protocol B {}
              protocol C {}

              class Another: A
              ,B, C  {}
              """

              self.fileURL = try? Temporary.makeSwiftFile(content: content)

              let sut = TypeConformanceAnalyzer(typeName: "B")
              let result = try? sut.analyze(fileURL: self.fileURL)

              expect(result?.doesConform) == true
            }
          }

        }
      }

      context("when a type implements a subclass") {
        it("is marked as conforms") {
          let content = """
          open class Some {}

          class Another: Some {}
          """

          self.fileURL = try? Temporary.makeSwiftFile(content: content)

          let sut = TypeConformanceAnalyzer(typeName: "Some")
          let result = try? sut.analyze(fileURL: self.fileURL)

          expect(result?.doesConform) == true
        }
      }

      context("when the type is not present") {
        it("is not marked as conforms") {
          let content = """
          protocol Some {}

          class Another: Some {}
          """

          self.fileURL = try? Temporary.makeSwiftFile(content: content)

          let sut = TypeConformanceAnalyzer(typeName: "AnotherType")
          let result = try? sut.analyze(fileURL: self.fileURL)

          expect(result?.doesConform) == false
        }
      }

    }
  }

}
