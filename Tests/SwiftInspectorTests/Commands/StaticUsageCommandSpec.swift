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
            let result = try? TestTask.run(withArguments: ["singleton"])
            expect(result?.didFail) == true
          }
        }

        context("with no --singleton argument") {
          it("fails") {
            let result = try? TestTask.run(withArguments: ["singleton", "--path", fileURL.path])
            expect(result?.didFail) == true
          }
        }

        context("with no --path argument") {
          it("fails") {
            let result = try? TestTask.run(withArguments: ["singleton", "--singleton", "SomeType.shared"])
            expect(result?.didFail) == true
          }
        }

      }

      context("with an empty --path argument") {
        it("fails") {
          let result = try? TestStaticUsageTask.run(singleton: "SomeType.shared", path: "")
          expect(result?.didFail) == true
        }
      }
      
      context("with an empty --singleton argument") {
        it("fails") {
          let result = try? TestStaticUsageTask.run(singleton: "", path: fileURL.path)
          expect(result?.didFail) == true
        }
      }

      context("with a type only --singleton argument") {
        it("fails") {
          let result = try? TestStaticUsageTask.run(singleton: "SomeType", path: fileURL.path)
          expect(result?.didFail) == true
        }
      }

      context("with a member only --singleton argument") {
        it("fails") {
          let result = try? TestStaticUsageTask.run(singleton: ".shared", path: fileURL.path)
          expect(result?.didFail) == true
        }
      }

      context("with multiple comma separated --singleton argument") {
        it("succeeds with spaces in between") {
          let result = try? TestStaticUsageTask.run(singleton: "SomeA.shared, SomeB.shared, SomeC.shared", path: fileURL.path)
          expect(result?.didSucceed) == true
        }

        it("succeeds with no spaces in between") {
          let result = try? TestStaticUsageTask.run(singleton: "SomeA.shared,SomeB.shared,SomeB.shared", path: fileURL.path)
          expect(result?.didSucceed) == true
        }
      }

      context("when path doesn't exist") {
        it("fails") {
          let result = try? TestStaticUsageTask.run(singleton: "SomeType.shared", path: "/abc")
          expect(result?.didFail) == true
        }
      }

      context("when path exists") {
        it("succeeds") {
          let result = try? TestStaticUsageTask.run(singleton: "SomeType.shared", path: fileURL.path)
          expect(result?.didSucceed) == true
        }
      }
      
    }
  }
}

private struct TestStaticUsageTask {
  fileprivate static func run(singleton: String, path: String) throws -> TaskStatus {
    try TestTask.run(withArguments: ["singleton", "--singleton", singleton, "--path", path])
  }
}
