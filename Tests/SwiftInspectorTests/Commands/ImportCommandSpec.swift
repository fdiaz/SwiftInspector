// Created by Francisco Diaz on 3/11/20.
// Copyright © 2020 Airbnb Inc. All rights reserved.

import Nimble
import Quick
import Foundation

@testable import SwiftInspectorKit

final class InspectorCommandSpec: QuickSpec {
  private var fileURL: URL!

  override func spec() {
    describe("run") {

      context("with no arguments") {
        it("fails") {
          let result = try? TestTask.run(withArguments: ["imports"])
          expect(result?.didFail) == true
        }
      }

      context("with an empty --path argument") {
        it("fails") {
          let result = try? TestStaticUsageTask.run(path: "")
          expect(result?.didFail) == true
        }
      }

      context("when path doesn't exist") {
        it("fails") {
          let result = try? TestStaticUsageTask.run(path: "/abc")
          expect(result?.didFail) == true
        }
      }

      context("when path exists") {
        var fileURL: URL!

        beforeEach {
          fileURL = try? Temporary.makeSwiftFile(content: "import Foundation")
        }

        afterEach {
          try? Temporary.removeItem(at: fileURL)
        }

        it("succeeds") {
          let result = try? TestStaticUsageTask.run(path: fileURL.path)
          expect(result?.didSucceed) == true
        }

        it("outputs to standard output") {
          let result = try? TestStaticUsageTask.run(path: fileURL.path)
          expect(result?.outputMessage).to(contain("Foundation"))
        }
      }

    }

  }
}

private struct TestStaticUsageTask {
  fileprivate static func run(path: String) throws -> TaskStatus {
    try TestTask.run(withArguments: ["imports", "--path", path])
  }
}
