// Created by Michael Bachand on 9/15/21.
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
import SwiftSyntax

@testable import SwiftInspectorVisitors

final class PropertyInfoParadigmSpec: QuickSpec {

  let undefinedConstantTestCase = PropertyInfo.Paradigm.undefinedConstant
  let undefinedConstantTestCaseData = """
    {
      "caseValue": 0
    }
    """.data(using: .utf8)!

  let definedConstantTestCase = PropertyInfo.Paradigm.definedConstant("= Foo()")
  let definedConstantTestCaseData = """
    {
      "caseValue": 1,
      "initializerDescription": "= Foo()"
    }
    """.data(using: .utf8)!

  let undefinedVariableTestCase = PropertyInfo.Paradigm.undefinedVariable
  let undefinedVariableTestCaseData = """
    {
      "caseValue": 2
    }
    """.data(using: .utf8)!

  let definedVariableTestCase = PropertyInfo.Paradigm.definedVariable("= Foo()")
  let definedVariableTestCaseData = """
    {
      "caseValue": 3,
      "initializerDescription": "= Foo()"
    }
    """.data(using: .utf8)!

  let computedVariableTestCase = PropertyInfo.Paradigm.computedVariable("{ Foo() }")
  let computedVariableTestCaseData = """
    {
      "caseValue": 4,
      "codeBlockDesciption": "{ Foo() }"
    }
    """.data(using: .utf8)!

  let protocolGetterTestCase = PropertyInfo.Paradigm.protocolGetter
  let protocolGetterTestCaseData = """
    {
      "caseValue": 5
    }
    """.data(using: .utf8)!

  let protocolGetterAndSetterTestCase = PropertyInfo.Paradigm.protocolGetterAndSetter
  let protocolGetterAndSetterTestCaseData = """
    {
      "caseValue": 6
    }
    """.data(using: .utf8)!

  override func spec() {
    describe("When decoding previously persisted PropertyInfo.Paradigm data") {
      let decoder = JSONDecoder()

      context("that represents an undefined constant property") {
        it("decodes the encoded paradigm") {
          expect(try decoder.decode(PropertyInfo.Paradigm.self, from: self.undefinedConstantTestCaseData))
            == self.undefinedConstantTestCase
        }
      }

      context("that represents a defined constant property") {
        it("decodes the encoded paradigm") {
          expect(try decoder.decode(PropertyInfo.Paradigm.self, from: self.definedConstantTestCaseData))
            == self.definedConstantTestCase
        }
      }

      context("that represents an undefined variable property") {
        it("decodes the encoded paradigm") {
          expect(try decoder.decode(PropertyInfo.Paradigm.self, from: self.undefinedVariableTestCaseData))
            == self.undefinedVariableTestCase
        }
      }

      context("that represents a defined variable property") {
        it("decodes the encoded paradigm") {
          expect(try decoder.decode(PropertyInfo.Paradigm.self, from: self.definedVariableTestCaseData))
            == self.definedVariableTestCase
        }
      }

      context("that represents a computed variable property") {
        it("decodes the encoded paradigm") {
          expect(try decoder.decode(PropertyInfo.Paradigm.self, from: self.computedVariableTestCaseData))
            == self.computedVariableTestCase
        }
      }

      context("that represents a protocol getter property") {
        it("decodes the encoded paradigm") {
          expect(try decoder.decode(PropertyInfo.Paradigm.self, from: self.protocolGetterTestCaseData))
            == self.protocolGetterTestCase
        }
      }

      context("that represents a protocol getter and setter property") {
        it("decodes the encoded paradigm") {
          expect(try decoder.decode(PropertyInfo.Paradigm.self, from: self.protocolGetterAndSetterTestCaseData))
            == self.protocolGetterAndSetterTestCase
        }
      }

      context("that is garabage") {
        let testData = """
          {
            "caseValue": -1,
          }
          """.data(using: .utf8)!

        it("throws an error") {
          expect(try decoder.decode(PropertyInfo.Paradigm.self, from: testData))
            .to(throwError(PropertyInfo.Paradigm.CodingError.unknownCase))
        }
      }
    }

    describe("When decoding a PropertyInfo.Paradigm data created with the current library version") {
      let decoder = JSONDecoder()
      let encoder = JSONEncoder()

      context("utilizing an undefined constant") {
        it("successfully decodes the data") {
          expect(try decoder.decode(PropertyInfo.Paradigm.self, from: try encoder.encode(self.undefinedConstantTestCase)))
            == self.undefinedConstantTestCase
        }
      }

      context("utilizing a defined constant") {
        it("successfully decodes the data") {
          expect(try decoder.decode(PropertyInfo.Paradigm.self, from: try encoder.encode(self.definedConstantTestCase)))
            == self.definedConstantTestCase
        }
      }

      context("utilizing an undefined variable") {
        it("successfully decodes the data") {
          expect(try decoder.decode(PropertyInfo.Paradigm.self, from: try encoder.encode(self.undefinedVariableTestCase)))
            == self.undefinedVariableTestCase
        }
      }

      context("utilizing a defined variable") {
        it("successfully decodes the data") {
          expect(try decoder.decode(PropertyInfo.Paradigm.self, from: try encoder.encode(self.definedVariableTestCase)))
            == self.definedVariableTestCase
        }
      }

      context("utilizing a computed variable") {
        it("successfully decodes the data") {
          expect(try decoder.decode(PropertyInfo.Paradigm.self, from: try encoder.encode(self.computedVariableTestCase)))
            == self.computedVariableTestCase
        }
      }

      context("utilizing a protocol getter") {
        it("successfully decodes the data") {
          expect(try decoder.decode(PropertyInfo.Paradigm.self, from: try encoder.encode(self.protocolGetterTestCase)))
            == self.protocolGetterTestCase
        }
      }

      context("utilizing a protocol getter and setter") {
        it("successfully decodes the data") {
          expect(try decoder.decode(PropertyInfo.Paradigm.self, from: try encoder.encode(self.protocolGetterAndSetterTestCase)))
            == self.protocolGetterAndSetterTestCase
        }
      }
    }
  }
}
