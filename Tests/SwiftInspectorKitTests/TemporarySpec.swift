// Created by Francisco Diaz on 10/9/19.
// Copyright © 2019 Airbnb Inc. All rights reserved.

import Foundation
import Nimble
import Quick

@testable import SwiftInspectorKit

final class TemporarySpec: QuickSpec {
  override func spec() {
    describe("makeSwiftFile") {
      it("creates a file") {
        guard let savedURL = try? Temporary.makeSwiftFile(content: "abc") else {
          return fail("Something went wrong when creating a temporary file. This shouldn't fail.")
        }

        expect(FileManager.default.fileExists(atPath: savedURL.path)) == true
      }

      it("saves the correct content") {
        let content = "protocol Some { }"
        guard let savedURL = try? Temporary.makeSwiftFile(content: content) else {
          return fail("Something went wrong when creating a temporary file. This shouldn't fail.")
        }

        let savedContent = try? String(contentsOf: savedURL, encoding: .utf8)
        expect(savedContent) == "protocol Some { }"
      }
    }

    describe("makeFolder") {
      it("creates a directory") {
        guard let folderURL = try? Temporary.makeFolder(name: "abc") else {
          return fail("Something went wrong when creating a temporary folder. This shouldn't fail.")
        }

        expect(FileManager.default.fileExists(atPath: folderURL.path)) == true
      }
    }

    describe("cleanFolder") {
      it("deletes all files from a directory") {
        guard let folderURL = try? Temporary.makeFolder(name: "abc") else {
          return fail("Something went wrong when creating a temporary folder. This shouldn't fail.")
        }

        expect(FileManager.default.fileExists(atPath: folderURL.path)) == true
      }
    }

    describe("removeItem") {
      it("deletes a existing file") {
        guard let savedURL = try? Temporary.makeSwiftFile(content: "abc") else {
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
