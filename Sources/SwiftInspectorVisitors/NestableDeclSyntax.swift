// Created by Dan Federman on 2/15/21.
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

import SwiftSyntax

protocol NestableDeclSyntax: SyntaxProtocol {
  var modifiers: ModifierListSyntax? { get }
  var identifier: TokenSyntax { get }
  var inheritanceClause: TypeInheritanceClauseSyntax? { get }
  var genericParameterClause: GenericParameterClauseSyntax? { get }
}

extension ClassDeclSyntax: NestableDeclSyntax {}
extension StructDeclSyntax: NestableDeclSyntax {}
extension EnumDeclSyntax: NestableDeclSyntax {
  var genericParameterClause: GenericParameterClauseSyntax? {
    // Not sure why enums's `GenericParameterClauseSyntax` has a different
    // accessor name, but it does. So let's remap.
    genericParameters
  }
}

