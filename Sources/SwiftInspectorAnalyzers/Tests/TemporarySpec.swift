// Created by Francisco Diaz on 10/9/19.
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

final class TemporarySpec: QuickSpec {
  override func spec() {
    describe("makeSwiftFile(content:name:)") {
      it("creates a file") {
        guard let savedURL = try? Temporary.makeFile(content: "abc") else {
          return fail("Something went wrong when creating a temporary file. This shouldn't fail.")
        }

        expect(FileManager.default.fileExists(atPath: savedURL.path)) == true
      }

      it("saves the correct content") {
        let content = "protocol Some { }"
        guard let savedURL = try? Temporary.makeFile(content: content) else {
          return fail("Something went wrong when creating a temporary file. This shouldn't fail.")
        }

        let savedContent = try? String(contentsOf: savedURL, encoding: .utf8)
        expect(savedContent) == "protocol Some { }"
      }

      it("uses the correct filename") {
        guard let savedURL = try? Temporary.makeFile(content: "", name: "SomeName") else {
          return fail("Something went wrong when creating a temporary file. This shouldn't fail.")
        }

        expect(savedURL.lastPathComponent) == "SomeName.swift"
      }
    }

    describe("makeFolder(name:)") {
      it("creates a directory") {
        guard let folderURL = try? Temporary.makeFolder(name: "abc") else {
          return fail("Something went wrong when creating a temporary folder. This shouldn't fail.")
        }

        expect(FileManager.default.fileExists(atPath: folderURL.path)) == true
      }
    }

    describe("removeItem(at:)") {
      it("deletes a existing file") {
        guard let savedURL = try? Temporary.makeFile(content: "abc") else {
          return fail("Something went wrong when creating a temporary file. This shouldn't fail.")
        }

        expect(FileManager.default.fileExists(atPath: savedURL.path)) == true

        try? Temporary.removeItem(at: savedURL)

        expect(FileManager.default.fileExists(atPath: savedURL.path)) == false
      }

      it("deletes an existing folder") {
        guard let folderURL = try? Temporary.makeFolder(name: "abc") else {
          return fail("Something went wrong when creating a temporary folder. This shouldn't fail.")
        }

        expect(FileManager.default.fileExists(atPath: folderURL.path)) == true

        try? Temporary.removeItem(at: folderURL)

        expect(FileManager.default.fileExists(atPath: folderURL.path)) == false

      }
    }
  }

}
