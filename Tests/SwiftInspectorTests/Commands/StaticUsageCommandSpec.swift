// Created by Francisco Diaz on 10/11/19.
// Copyright © 2019 Airbnb Inc. All rights reserved.

import Foundation
import Nimble
import Quick
@testable import SwiftInspectorKit

final class StaticUsageCommandSpec: QuickSpec {
  
  override func spec() {
    describe("run") {
      var fileURL: URL!

      beforeEach {
        fileURL = try? Temporary.makeSwiftFile(content: "")
      }

      afterEach {
        try? Temporary.removeItem(at: fileURL)
      }

      context("when missing arguments") {

        context("with no arguments") {
          it("fails") {
            let result = try? TestTask.run(withArguments: ["static-usage"])
            expect(result?.didFail) == true
          }
        }

        context("with no --statics argument") {
          it("fails") {
            let result = try? TestTask.run(withArguments: ["static-usage", "--path", fileURL.path])
            expect(result?.didFail) == true
          }
        }

        context("with no --path argument") {
          it("fails") {
            let result = try? TestTask.run(withArguments: ["static-usage", "--statics", "SomeType.shared"])
            expect(result?.didFail) == true
          }
        }

      }

      context("with an empty --path argument") {
        it("fails") {
          let result = try? TestStaticUsageTask.run(statics: "SomeType.shared", path: "")
          expect(result?.didFail) == true
        }
      }
      
      context("with an empty --statics argument") {
        it("fails") {
          let result = try? TestStaticUsageTask.run(statics: "", path: fileURL.path)
          expect(result?.didFail) == true
        }
      }

      context("with a type only --statics argument") {
        it("fails") {
          let result = try? TestStaticUsageTask.run(statics: "SomeType", path: fileURL.path)
          expect(result?.didFail) == true
        }
      }

      context("with a member only --statics argument") {
        it("fails") {
          let result = try? TestStaticUsageTask.run(statics: ".shared", path: fileURL.path)
          expect(result?.didFail) == true
        }
      }

      context("with multiple comma separated --statics argument") {
        it("succeeds with spaces in between") {
          let result = try? TestStaticUsageTask.run(statics: "SomeA.shared, SomeB.shared, SomeC.shared", path: fileURL.path)
          expect(result?.didSucceed) == true
        }

        it("succeeds with no spaces in between") {
          let result = try? TestStaticUsageTask.run(statics: "SomeA.shared,SomeB.shared,SomeB.shared", path: fileURL.path)
          expect(result?.didSucceed) == true
        }
      }

      context("when path doesn't exist") {
        it("fails") {
          let result = try? TestStaticUsageTask.run(statics: "SomeType.shared", path: "/abc")
          expect(result?.didFail) == true
        }
      }

      context("when path exists") {
        it("succeeds") {
          let result = try? TestStaticUsageTask.run(statics: "SomeType.shared", path: fileURL.path)
          expect(result?.didSucceed) == true
        }
      }
      
    }
  }
}

private struct TestStaticUsageTask {
  fileprivate static func run(statics: String, path: String) throws -> TaskStatus {
    try TestTask.run(withArguments: ["static-usage", "--statics", statics, "--path", path])
  }
}
