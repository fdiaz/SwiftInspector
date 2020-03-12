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

      context("with no --type-names argument") {
        it("fails") {
          let result = try? TestTask.run(withArguments: ["type-conformance", "--path", "."])
          expect(result?.didFail) == true
        }
      }

      context("with an empty --type-names argument") {
        it("fails") {
          let result = try? TestTask.run(withArguments: ["type-conformance", "--type-names", "", "--path", "/abc"])
          expect(result?.didFail) == true
        }
      }

      context("with no --path argument") {
        it("fails") {
          let result = try? TestTask.run(withArguments: ["type-conformance", "--type-names", "SomeType"])
          expect(result?.didFail) == true
        }
      }

      context("with an empty --path argument") {
        it("fails") {
          let result = try? TestTask.run(withArguments: ["type-conformance", "--type-names", "SomeType", "--path", ""])
          expect(result?.didFail) == true
        }
      }

      context("with all arguments") {
        context("when path doesn't exist") {
          it("fails") {
            let result = try? TestTask.run(withArguments: ["type-conformance", "--type-names", "SomeType", "--path", "/abc"])
            expect(result?.didSucceed) == false
          }
        }

        context("when path exists") {
          var fileURL: URL!
          var path: String!

          beforeEach {
            fileURL = try? Temporary.makeSwiftFile(content: "")
            path = fileURL?.path ?? ""
          }

          afterEach {
            try? Temporary.removeItem(at: fileURL)
          }

          context("when type conformance contains multiple types") {
            it("succeeds") {
              let result = try? TestTask.run(withArguments: ["type-conformance", "--type-names", "SomeType", "AnotherType", "AThirdType", "--path", path])
              expect(result?.didSucceed) == true
            }
          }

          context("when type conformance contains one type") {
            it("succeeds") {
              let result = try? TestTask.run(withArguments: ["type-conformance", "--type-names", "SomeType", "--path", path])
              expect(result?.didSucceed) == true
            }
          }

        }

      }

    }
  }
}
