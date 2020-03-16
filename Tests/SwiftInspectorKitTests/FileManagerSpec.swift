// Created by Francisco Diaz on 3/14/20.
// Copyright © 2020 Airbnb Inc. All rights reserved.

import Foundation
import Nimble
import Quick

@testable import SwiftInspectorKit

final class FileManagerSpec: QuickSpec {
  override func spec() {
    describe("swiftFileURLs(at:)") {
      var fileManager: FileManager!
      beforeEach {
        fileManager = FileManager.default
      }

      context("with a file") {
        var fileURL: URL!
        beforeEach {
          fileURL = try! Temporary.makeFile(content: "")
        }
        afterEach {
          try? Temporary.removeItem(at: fileURL)
        }

        it("returns the file path") {
          expect(fileManager.swiftFiles(at: fileURL)) == [fileURL]
        }
      }

      context("with a directory") {
        var parentURL: URL!
        beforeEach {
          parentURL = try! Temporary.makeFolder()
        }
        afterEach {
          try? Temporary.removeItem(at: parentURL)
        }

        context("when there are no swift files") {
          it("returns an empty array") {
            expect(fileManager.swiftFiles(at: parentURL)) == []
          }

          it("does not return other file extensions") {
            let _ = try! Temporary.makeFile(content: "", fileExtension: "txt", atPath: parentURL.path)
            let _ = try! Temporary.makeFile(content: "", fileExtension: "png", atPath: parentURL.path)

            expect(fileManager.swiftFiles(at: parentURL)) == []
          }
        }

        context("when there is one swift file") {
          it("returns an array with that file URL") {
            let fileURL = try! Temporary.makeFile(content: "", atPath: parentURL.path)
            expect(fileManager.swiftFiles(at: parentURL)) == [fileURL]
          }
        }

        context("when there are multiple swift files") {
          var fileURL1: URL!
          var fileURL2: URL!

          beforeEach {
            fileURL1 = try! Temporary.makeFile(content: "abc", atPath: parentURL.path)
            fileURL2 = try! Temporary.makeFile(content: "xyz", atPath: parentURL.path)
          }

          it("returns an array with both of the file URLs") {
            let sut = fileManager.swiftFiles(at: parentURL)

            expect(sut).to(contain([fileURL1, fileURL2]))
          }

          it("contains only 2 elements") {
            let sut = fileManager.swiftFiles(at: parentURL)

            expect(sut.count) == 2
          }
        }

        context("when there are swift files in subfolders") {
          it("it returns the swift file in the subfolder") {
            let parentURL = try! Temporary.makeFolder()
            let subfolderURL = try! Temporary.makeFolder(parentPath: parentURL.path)
            let fileURL = try! Temporary.makeFile(content: "", atPath: subfolderURL.path)

            expect(fileManager.swiftFiles(at: parentURL)) == [fileURL]
          }
        }
      }

    }
  }
}
