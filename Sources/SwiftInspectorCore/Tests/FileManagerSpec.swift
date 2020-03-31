// Created by Francisco Diaz on 3/14/20.
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

final class FileManagerSpec: QuickSpec {
  override func spec() {
    var fileManager: FileManager!
    
    beforeEach {
      fileManager = FileManager.default
    }

    describe("swiftFileURLs(at:)") {

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
          it("returns the swift file in the subfolder") {
            let parentURL = try! Temporary.makeFolder()
            let subfolderURL = try! Temporary.makeFolder(parentPath: parentURL.path)
            let fileURL = try! Temporary.makeFile(content: "", atPath: subfolderURL.path)

            expect(fileManager.swiftFiles(at: parentURL)) == [fileURL]
          }
        }

        context("with a subfolder with spaces")  {
          it("returns the swift files in the subfolder") {
            let parentURL = try! Temporary.makeFolder(parentPath: parentURL.path)
            let subfolderURL = try! Temporary.makeFolder(name: "Some Folder Name", parentPath: parentURL.path)
            let fileURL = try! Temporary.makeFile(content: "", atPath: subfolderURL.path)

            expect(fileManager.swiftFiles(at: parentURL)) == [fileURL]

          }
        }
      }

    }

    describe("isSwiftFile(at:)") {
      context("with a directory") {
        var parentURL: URL!
        beforeEach {
          parentURL = try! Temporary.makeFolder()
        }
        afterEach {
          try? Temporary.removeItem(at: parentURL)
        }

        it("returns false") {
          expect(fileManager.isSwiftFile(at: parentURL)) == false
        }
      }

      context("with a file") {
        var fileURL: URL!

        afterEach {
          try? Temporary.removeItem(at: fileURL)
        }

        it("returns false if it's not a Swift file") {
          fileURL = try! Temporary.makeFile(content: "", fileExtension: ".txt")
          expect(fileManager.isSwiftFile(at: fileURL)) == false
        }

        it("returns true if it's a Swift file") {
          fileURL = try! Temporary.makeFile(content: "", fileExtension: ".swift")
          expect(fileManager.isSwiftFile(at: fileURL)) == true
        }
      }

      context("with an invalid URL") {
        it("returns false") {
          let fileURL = URL(fileURLWithPath: "")
          expect(fileManager.isSwiftFile(at: fileURL)) == false
        }
      }

    }

  }
}
