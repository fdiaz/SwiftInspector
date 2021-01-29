// Created by Dan Federman on 1/28/21.
//
// Copyright © 2021 Dan Federman
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
import SwiftInspectorTestHelpers

@testable import SwiftInspectorVisitors

final class FileVisitorSpec: QuickSpec {
  private var sut = FileVisitor(fileURL: URL(fileURLWithPath: #filePath))

  override func spec() {
    beforeEach {
      self.sut = FileVisitor(fileURL: URL(fileURLWithPath: #filePath))
    }

    describe("visit(_:)") {
      context("file with nested types") {
        beforeEach {
          let content = """
              import Foundation

              struct TestStruct {
                struct InnerStruct {}
                // TODO: find this definition
                class InnerClass {}
                // TODO: find this definition
                enum InnerEnum {}
              }

              // TODO: find this definition and inner definitions
              class TestClass {
                struct InnerStruct {}
                class InnerClass {}
                enum InnerEnum {}
              }

              // TODO: find this definition and inner definitions
              enum TestEnum {
                struct InnerStruct {}
                class InnerClass {}
                enum InnerEnum {}
              }

              protocol TestProtocol {}

              // TODO: find this definition and inner definitions.
              // TODO: find and propogate this generic constraint to inner types.
              extension Array where Element == Int {
                struct InnerStruct {}
                class InnerClass {}
                enum InnerEnum {}
              }
              """

          try? VisitorExecutor.walkVisitor(
            self.sut,
            overContent: content)
        }

        it("finds the import") {
          expect(self.sut.fileInfo.imports.count) == 1
          expect(self.sut.fileInfo.imports.first?.mainModule) == "Foundation"
        }

        it("finds TestStruct") {
          let matchingStructs = self.sut.fileInfo.structs.filter { $0.name == "TestStruct" }
          expect(matchingStructs.count) == 1
        }

        it("finds TestStruct.InnerStruct") {
          let matchingStructs = self.sut.fileInfo.structs.filter {
            $0.name == "InnerStruct"
              && $0.parentTypeName == "TestStruct"
          }
          expect(matchingStructs.count) == 1
        }

        it("finds TestProtocol") {
          let matchingStructs = self.sut.fileInfo.protocols.filter {
            $0.name == "TestProtocol"
          }
          expect(matchingStructs.count) == 1
        }
      }
    }
  }
}
