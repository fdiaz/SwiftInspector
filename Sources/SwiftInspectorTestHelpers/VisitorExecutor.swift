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
import SwiftSyntax

public final class VisitorExecutor {

  /// Creates a Swift file in the temporary directory with the provided content, and then walks the provided visitor along the content's syntax.
  ///
  /// - Parameters:
  ///   - content: The content to turn into source and walk.
  ///   - visitor: The visitor to walk along the content syntax.
  /// - Returns: The location of the file with content written to it.
  public static func createFile<Visitor: SyntaxVisitor>(
    withContent content: String,
    andWalk visitor: Visitor)
  throws
  -> URL
  {
    let fileURL = try Temporary.makeFile(content: content)
    let syntax: SourceFileSyntax = try SyntaxParser.parse(fileURL)
    visitor.walk(syntax)
    return fileURL
  }

  /// Creates a Swift file in the temporary directory with the provided content, and then walks the provided syntax rewriter along the content's syntax.
  ///
  /// - Parameters:
  ///   - content: The content to turn into source and walk.
  ///   - rewriter: The syntax rewriter to walk along the content syntax.
  /// - Returns: The location of the file with content written to it.
  /// - Note: Use a visitor when possible. Rewriters should be used to work around this bug: https://bugs.swift.org/browse/SR-11591
  public static func createFile<Rewriter: SyntaxRewriter>(
    withContent content: String,
    andWalk rewriter: Rewriter)
  throws
  -> URL
  {
    let fileURL = try Temporary.makeFile(content: content)
    let syntax: SourceFileSyntax = try SyntaxParser.parse(fileURL)
    _ = rewriter.visit(syntax)
    return fileURL
  }
}
