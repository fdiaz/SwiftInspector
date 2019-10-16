// Created by Francisco Diaz on 10/11/19.
// Copyright © 2019 Airbnb Inc. All rights reserved.

import Foundation
import Nimble
import Quick
@testable import SwiftInspectorKit

final class TypeConformanceCommandSpec: QuickSpec {

  override func spec() {
    describe("run") {
      context("with no arguments") {
        it("fails") {
          let result = try? TestTask.run(withArguments: ["type-conformance"])
          expect(result?.didFail) == true
        }
      }

      context("with no --type-name argument") {
        it("fails") {
          let result = try? TestTask.run(withArguments: ["type-conformance", "--path", "."])
          expect(result?.didFail) == true
        }
      }

      context("with an empty --type-name argument") {
        it("fails") {
          let result = try? TestTask.run(withArguments: ["type-conformance", "--type-name", "", "--path", "/abc"])
          expect(result?.didFail) == true
        }
      }

      context("with no --path argument") {
        it("fails") {
          let result = try? TestTask.run(withArguments: ["type-conformance", "--type-name", "SomeType"])
          expect(result?.didFail) == true
        }
      }

      context("with an empty --path argument") {
        it("fails") {
          let result = try? TestTask.run(withArguments: ["type-conformance", "--type-name", "SomeType", "--path", ""])
          expect(result?.didFail) == true
        }
      }

      context("with all arguments") {
        context("when path doesn't exist") {
          it("fails") {
            let result = try? TestTask.run(withArguments: ["type-conformance", "--type-name", "SomeType", "--path", "/abc"])
            expect(result?.didSucceed) == false
          }
        }

        context("when path exists") {
          it("succeeds") {
            let fileURL = try? Temporary.makeSwiftFile(content: "")
            let result = try? TestTask.run(withArguments: ["type-conformance", "--type-name", "SomeType", "--path", fileURL?.path ?? ""])
            expect(result?.didSucceed) == true
          }
        }

      }

    }
  }
}
