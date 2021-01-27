// Created by Dan Federman on 1/27/21.
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

final class StandardAnalyzerSpec: QuickSpec {

  private final class MockVisitor: SyntaxVisitor {
    var ifStatementSyntaxVisitCount = 0
    override func visitPost(_ node: IfStmtSyntax) {
      ifStatementSyntaxVisitCount += 1
    }
  }

  private final class MockRewriter: SyntaxRewriter {
    var ifStatementSyntaxVisitCount = 0
    override func visit(_ node: IfStmtSyntax) -> StmtSyntax {
      ifStatementSyntaxVisitCount += 1
      return super.visit(node)
    }
  }

  override func spec() {
    describe("analyze(fileURL:withVisitor:)") {
      context("with a visitor") {
        it("walks the visitor over the content") {
          let visitor = MockVisitor()
          try VisitorExecutor.walkVisitor(visitor, overContent: "if true {}")

          expect(visitor.ifStatementSyntaxVisitCount) == 1
        }
      }

      context("with a rewriter") {
        it("walks the rewriter over the content") {
          let visitor = MockRewriter()
          try VisitorExecutor.walkVisitor(visitor, overContent: "if true {}")

          expect(visitor.ifStatementSyntaxVisitCount) == 1
        }
      }
    }
  }
}
