// Created by Francisco Diaz on 3/25/20.
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
@testable import SwiftInspectorCore

final class TypealiasCommandSpec: QuickSpec {
  override func spec() {
    var fileURL: URL!
    var path: String!

    beforeEach {
      fileURL = try? Temporary.makeFile(content: "final class Some: SomeType { }")
      path = fileURL?.path ?? ""
    }

    afterEach {
      try? Temporary.removeItem(at: fileURL)
    }

    describe("run") {
      context("with no arguments") {
        it("fails") {
          let result = try? TestTask.run(withArguments: ["typealias"])
          expect(result?.didFail) == true
        }
      }

      context("with no --name argument") {
        it("fails") {
          let result = try? TestTask.run(withArguments: ["typealias", "--path", path])
          expect(result?.didFail) == true
        }
      }

      context("with an empty --name argument") {
        it("fails") {
          let result = try? TestTask.run(withArguments: ["typealias", "--name", "", "--path", path])
          expect(result?.didFail) == true
        }
      }

      context("with all arguments") {
        context("when path doesn't exist") {
          it("fails") {
            let result = try? TestTask.run(withArguments: ["typealias", "--name", "SomeAlias", "--path", "/abc"])
            expect(result?.didSucceed) == false
          }
        }

        context("when path exists") {
          it("succeeds") {
            let result = try? TestTask.run(withArguments: ["typealias", "--name", "SomeAlias", "--path", path])
            expect(result?.didSucceed) == true
          }
        }

      }

    }
  }
}
