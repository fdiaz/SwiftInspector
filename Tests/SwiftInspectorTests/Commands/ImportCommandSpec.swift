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

      context("when path is a folder") {
        var folderURL: URL!
        beforeEach {
          folderURL = try! Temporary.makeFolder()
        }
        afterEach {
          try! Temporary.removeItem(at: folderURL)
        }

        it("succeeds") {
          let result = try? TestStaticUsageTask.run(path: folderURL.path)

          expect(result?.didSucceed) == true
        }

        it("outputs the correct modules") {
          let _ = try? Temporary.makeFile(
            content: """
                     import Foundation
                     import UIKit
                     import MyService
                     """,
            atPath: folderURL.path)

          let result = try? TestStaticUsageTask.run(path: folderURL.path)
          let outputMessageLines = result?.outputMessage?.split { $0.isNewline }
          expect(outputMessageLines).to(contain(["Foundation", "UIKit", "MyService"]))
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
