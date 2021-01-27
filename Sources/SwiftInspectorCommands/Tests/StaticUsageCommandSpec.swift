// Created by Francisco Diaz on 10/11/19.
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

import Foundation
import Nimble
import Quick
@testable import SwiftInspectorAnalyzers

final class StaticUsageCommandSpec: QuickSpec {
  
  override func spec() {
    describe("run") {
      var fileURL: URL!

      beforeEach {
        fileURL = try? Temporary.makeFile(content: "")
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

      context("with multiple separated --statics argument") {
        it("succeeds passing multiple --statics") {
          let result = try? TestTask.run(withArguments: ["static-usage", "--statics", "A.some", "--statics", "B.some", "--path", fileURL.path])
          expect(result?.didSucceed) == true
        }

        it("succeeds passing one --statics") {
          let result = try? TestTask.run(withArguments: ["static-usage", "--statics", "A.some", "B.some", "--path", fileURL.path])
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

        it("outputs to standard output") {
          fileURL = try? Temporary.makeFile(content: "SomeType.shared")
          let result = try? TestStaticUsageTask.run(statics: "SomeType.shared", path: fileURL.path)
          expect(result?.outputMessage).to(contain("SomeType.shared true"))
        }

        it("outputs the path to standard output") {
          let result = try? TestStaticUsageTask.run(statics: "SomeType.shared", path: fileURL.path)
          expect(result?.outputMessage).to(contain(fileURL.lastPathComponent))
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
