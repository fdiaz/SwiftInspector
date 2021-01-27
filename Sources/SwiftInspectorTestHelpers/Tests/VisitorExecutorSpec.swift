// Created by Dan Federman on 1/26/21.
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
import SwiftSyntax

@testable import SwiftInspectorTestHelpers

final class VisitorExecutorSpec: QuickSpec {
  private final class MockVisitor: SyntaxVisitor {
    var ifSyntaxVisitCount = 0
    override func visitPost(_ node: IfStmtSyntax) {
      ifSyntaxVisitCount += 1
    }
  }
  private final class MockRewriter: SyntaxRewriter {
    var ifSyntaxVisitCount = 0
    override func visit(_ node: IfStmtSyntax) -> StmtSyntax {
      ifSyntaxVisitCount += 1
      return super.visit(node)
    }
  }

  override func spec() {
    describe("createFile(withContent:andWalk:) with visitor") {
      it("creates a file") {
        do {
          let savedURL = try VisitorExecutor.createFile(withContent: "abc", andWalk: MockVisitor())
          expect(FileManager.default.fileExists(atPath: savedURL.path)) == true
        } catch {
          fail("Encountered error \(error)")
        }
      }

      it("saves the correct content") {
        do {
          let content = "protocol Some { }"
          let savedURL = try VisitorExecutor.createFile(withContent: content, andWalk: MockVisitor())

          let savedContent = try String(contentsOf: savedURL, encoding: .utf8)
          expect(savedContent) == "protocol Some { }"
        } catch {
          fail("Encountered error \(error)")
        }
      }

      it("walks the visitor over the content") {
        do {
          let visitor = MockVisitor()
          _ = try VisitorExecutor.createFile(withContent: "if true {}", andWalk: visitor)

          expect(visitor.ifSyntaxVisitCount) == 1
        } catch {
          fail("Encountered error \(error)")
        }
      }
    }

    describe("createFile(withContent:andWalk:) with rewriter") {
      it("creates a file") {
        do {
          let savedURL = try VisitorExecutor.createFile(withContent: "abc", andWalk: MockRewriter())
          expect(FileManager.default.fileExists(atPath: savedURL.path)) == true
        } catch {
          fail("Encountered error \(error)")
        }
      }

      it("saves the correct content") {
        do {
          let content = "protocol Some { }"
          let savedURL = try VisitorExecutor.createFile(withContent: content, andWalk: MockRewriter())

          let savedContent = try String(contentsOf: savedURL, encoding: .utf8)
          expect(savedContent) == "protocol Some { }"
        } catch {
          fail("Encountered error \(error)")
        }
      }

      it("walks the rewriter over the content") {
        do {
          let visitor = MockRewriter()
          _ = try VisitorExecutor.createFile(withContent: "if true {}", andWalk: visitor)

          expect(visitor.ifSyntaxVisitCount) == 1
        } catch {
          fail("Encountered error \(error)")
        }
      }

    }
  }
}
