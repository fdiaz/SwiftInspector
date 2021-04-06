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
                class InnerClass {}
                enum InnerEnum {}
                typealias InnerTypealias = Void
              }

              class TestClass {
                struct InnerStruct {}
                class InnerClass {}
                enum InnerEnum {}
                typealias InnerTypealias = Void
              }

              enum TestEnum {
                struct InnerStruct {}
                class InnerClass {}
                enum InnerEnum {}
                typealias InnerTypealias = Void
              }

              protocol TestProtocol {}

              // TODO: propagate this generic constraint to inner types.
              extension Array where Element == Int {
                struct InnerStruct {}
                class InnerClass {}
                enum InnerEnum {}
                typealias InnerTypealias = Void
              }

              typealias SortableSet<Element: Hashable & Comparable> = Set<Element>
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
          let matching = self.sut.fileInfo.structs.filter {
            $0.name == "TestStruct"
          }
          expect(matching.count) == 1
        }

        it("finds TestStruct.InnerStruct") {
          let matching = self.sut.fileInfo.structs.filter {
            $0.name == "InnerStruct"
              && $0.parentType?.asSource == "TestStruct"
          }
          expect(matching.count) == 1
        }

        it("finds TestStruct.InnerClass") {
          let matching = self.sut.fileInfo.classes.filter {
            $0.name == "InnerClass"
              && $0.parentType?.asSource == "TestStruct"
          }
          expect(matching.count) == 1
        }

        it("finds TestStruct.InnerEnum") {
          let matching = self.sut.fileInfo.enums.filter {
            $0.name == "InnerEnum"
              && $0.parentType?.asSource == "TestStruct"
          }
          expect(matching.count) == 1
        }

        it("finds TestStruct.InnerTypealias") {
          let matching = self.sut.fileInfo.typealiases.filter {
            $0.name == "InnerTypealias"
              && $0.parentType?.asSource == "TestStruct"
          }
          expect(matching.count) == 1
        }

        it("finds TestClass") {
          let matching = self.sut.fileInfo.classes.filter {
            $0.name == "TestClass"
          }
          expect(matching.count) == 1
        }

        it("finds TestClass.InnerStruct") {
          let matching = self.sut.fileInfo.structs.filter {
            $0.name == "InnerStruct"
              && $0.parentType?.asSource == "TestClass"
          }
          expect(matching.count) == 1
        }

        it("finds TestClass.InnerClass") {
          let matching = self.sut.fileInfo.classes.filter {
            $0.name == "InnerClass"
              && $0.parentType?.asSource == "TestClass"
          }
          expect(matching.count) == 1
        }

        it("finds TestClass.InnerEnum") {
          let matching = self.sut.fileInfo.enums.filter {
            $0.name == "InnerEnum"
              && $0.parentType?.asSource == "TestClass"
          }
          expect(matching.count) == 1
        }

        it("finds TestClass.InnerTypealias") {
          let matching = self.sut.fileInfo.typealiases.filter {
            $0.name == "InnerTypealias"
              && $0.parentType?.asSource == "TestClass"
          }
          expect(matching.count) == 1
        }

        it("finds TestEnum") {
          let matching = self.sut.fileInfo.enums.filter {
            $0.name == "TestEnum"
              && $0.parentType?.asSource == nil
          }
          expect(matching.count) == 1
        }

        it("finds TestEnum.InnerStruct") {
          let matching = self.sut.fileInfo.structs.filter {
            $0.name == "InnerStruct"
              && $0.parentType?.asSource == "TestEnum"
          }
          expect(matching.count) == 1
        }

        it("finds TestEnum.InnerClass") {
          let matching = self.sut.fileInfo.classes.filter {
            $0.name == "InnerClass"
              && $0.parentType?.asSource == "TestEnum"
          }
          expect(matching.count) == 1
        }

        it("finds TestEnum.InnerEnum") {
          let matching = self.sut.fileInfo.enums.filter {
            $0.name == "InnerEnum"
              && $0.parentType?.asSource == "TestEnum"
          }
          expect(matching.count) == 1
        }

        it("finds TestEnum.InnerTypealias") {
          let matching = self.sut.fileInfo.typealiases.filter {
            $0.name == "InnerTypealias"
              && $0.parentType?.asSource == "TestEnum"
          }
          expect(matching.count) == 1
        }

        it("finds TestProtocol") {
          let matching = self.sut.fileInfo.protocols.filter {
            $0.name == "TestProtocol"
          }
          expect(matching.count) == 1
        }

        it("finds Array extension") {
          let matching = self.sut.fileInfo.extensions.filter {
            $0.typeDescription.asSource == "Array"
              && $0.genericRequirements.first?.leftType.asSource == "Element"
              && $0.genericRequirements.first?.rightType.asSource == "Int"
              && $0.genericRequirements.first?.relationship == .equals
          }
          expect(matching.count) == 1
        }

        it("finds Array.InnerStruct") {
          let matching = self.sut.fileInfo.structs.filter {
            $0.name == "InnerStruct"
              && $0.parentType?.asSource == "Array"
          }
          expect(matching.count) == 1
        }

        it("finds Array.InnerClass") {
          let matching = self.sut.fileInfo.classes.filter {
            $0.name == "InnerClass"
              && $0.parentType?.asSource == "Array"
          }
          expect(matching.count) == 1
        }

        it("finds Array.InnerEnum") {
          let matching = self.sut.fileInfo.enums.filter {
            $0.name == "InnerEnum"
              && $0.parentType?.asSource == "Array"
          }
          expect(matching.count) == 1
        }

        it("finds Array.InnerTypealias") {
          let matching = self.sut.fileInfo.typealiases.filter {
            $0.name == "InnerTypealias"
              && $0.parentType?.asSource == "Array"
          }
          expect(matching.count) == 1
        }

        it("finds typealias SortableSet") {
          let matching = self.sut.fileInfo.typealiases.filter {
            $0.name == "SortableSet"
              && $0.genericParameters.first?.name == "Element"
              && $0.genericParameters.first?.inheritsFrom?.asSource == "Hashable & Comparable"
          }
          expect(matching.count) == 1
        }
      }
    }
  }
}
