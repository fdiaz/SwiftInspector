// Created by Dan Federman on 2/9/21.
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
import SwiftSyntax

final class DeclarationModifierVisitor: SyntaxVisitor {

  public var modifiers: Modifiers {
    rawModifiers.reduce(Modifiers()) { partialResult, nextStringModifier in
      partialResult.union(Modifiers(stringValue: nextStringModifier))
    }
  }

  public override func visit(_ node: DeclModifierSyntax) -> SyntaxVisitorContinueKind {
    if
      let leftParen = node.detailLeftParen,
      let detail = node.detail,
      let rightParen = node.detailRightParen
    {
      rawModifiers.append(node.name.text + leftParen.text + detail.text + rightParen.text)
    } else {
      rawModifiers.append(node.name.text)
    }

    return .skipChildren
  }

  // MARK: Private

  private var rawModifiers = [String]()

}
