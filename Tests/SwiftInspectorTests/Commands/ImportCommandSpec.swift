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
          fileURL = try? Temporary.makeFile(content: "@testable import struct Foundation.Some")
        }

        afterEach {
          try? Temporary.removeItem(at: fileURL)
        }

        it("succeeds") {
          let result = try? TestStaticUsageTask.run(path: fileURL.path)
          expect(result?.didSucceed) == true
        }

        it("outputs only the main module by default") {
          let result = try? TestStaticUsageTask.run(path: fileURL.path)
          expect(result?.outputMessage) == "Foundation\n"
        }

        it("outputs the full import if full is passed") {
          let result = try? TestStaticUsageTask.run(path: fileURL.path, arguments: ["--mode", "full"])
          expect(result?.outputMessage).to(contain("@testable struct Foundation.Some"))
        }
      }

    }

  }
}

private struct TestStaticUsageTask {
  fileprivate static func run(path: String, arguments: [String] = []) throws -> TaskStatus {
    let arguments = ["imports", "--path", path] + arguments
    return try TestTask.run(withArguments: arguments)
  }
}
