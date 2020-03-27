// Created by Francisco Diaz on 3/27/20.
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

import Nimble
import Quick
import Foundation

@testable import SwiftInspectorCore

final class InitializerCommandSpec: QuickSpec {
  override func spec() {
    describe("run") {

      context("with no arguments") {
        it("fails") {
          let result = try? TestTask.run(withArguments: ["initializer"])
          expect(result?.didFail) == true
        }
      }

      context("when path is invalid") {
        it("fails when empty") {
          let result = try? TestTask.run(withArguments: ["initializer", "--path", ""])
          expect(result?.didFail) == true
        }

        it("fails when it doesn't exist") {
          let result = try? TestTask.run(withArguments: ["initializer", "--path", "/fake/path"])
          expect(result?.didFail) == true
        }
      }

      context("when name is passed and path exists") {
        var fileURL: URL!

        beforeEach {
          fileURL = try? Temporary.makeFile(content: "")
        }

        afterEach {
          try? Temporary.removeItem(at: fileURL)
        }

        it("fails when name is empty") {
          let result = try? TestTask.run(withArguments: ["initializer", "--path", fileURL.path, "--name", ""])
          expect(result?.didFail) == true
        }

        it("succeeds") {
          let result = try? TestTask.run(withArguments: ["initializer", "--path", fileURL.path, "--name", "SomeName"])
          expect(result?.didSucceed) == true
        }
      }

    }
  }
}
