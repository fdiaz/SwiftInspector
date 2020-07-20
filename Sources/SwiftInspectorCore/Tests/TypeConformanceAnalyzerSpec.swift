// Created by Francisco Diaz on 10/14/19.
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

import Nimble
import Quick
import Foundation

@testable import SwiftInspectorCore

final class TypeConformanceAnalyzerSpec: QuickSpec {
  private var fileURL: URL!
  
  override func spec() {
    afterEach {
      guard let fileURL = self.fileURL else {
        return
      }
      try? Temporary.removeItem(at: fileURL)
    }
    
    describe("analyze(fileURL:)") {
      var result: TypeConformance!
      
      context("when a type conforms to a protocol") {
        context("with only one conformance") {
          beforeEach {
            let content = """
            protocol Some {}

            class Another: Some {}
            """
            
            self.fileURL = try? Temporary.makeFile(content: content)
            let sut = TypeConformanceAnalyzer(typeName: "Some")
            result = try? sut.analyze(fileURL: self.fileURL)
          }
          
          it("conforms") {
            expect(result?.doesConform) == true
          }
          
          it("returns the conforming type name") {
            expect(result?.conformingTypeNames) == ["Another"]
          }
        }

        context("with a struct conforming to the protocol") {
          beforeEach {
            let content = """
            protocol Some {}

            struct Another: Some {}
            """

            self.fileURL = try? Temporary.makeFile(content: content)
            let sut = TypeConformanceAnalyzer(typeName: "Some")
            result = try? sut.analyze(fileURL: self.fileURL)
          }

          it("conforms") {
            expect(result?.doesConform) == true
          }

          it("returns the conforming type name") {
            expect(result?.conformingTypeNames) == ["Another"]
          }
        }
        
        context("with an enum conforming to the protocol") {
          beforeEach {
            let content = """
            protocol Some {}

            enum Another: Some {}
            """

            self.fileURL = try? Temporary.makeFile(content: content)
            let sut = TypeConformanceAnalyzer(typeName: "Some")
            result = try? sut.analyze(fileURL: self.fileURL)
          }

          it("conforms") {
            expect(result?.doesConform) == true
          }

          it("returns the conforming type name") {
            expect(result?.conformingTypeNames) == ["Another"]
          }
        }

        context("when the type has multiple conformances") {
          beforeEach {
            let content = """
              protocol Foo {}
              protocol Bar {}

              class Another: Foo, Bar {}

              class Second: Foo {}
              """
            
            self.fileURL = try? Temporary.makeFile(content: content)
            let sut = TypeConformanceAnalyzer(typeName: "Foo")
            result = try? sut.analyze(fileURL: self.fileURL)
          }
          
          it("conforms") {
            expect(result?.doesConform) == true
          }
          
          it("returns the conforming type names") {
            expect(result?.conformingTypeNames) == ["Another", "Second"]
          }
        }
        
        context("when the types conform in a different line") {
          beforeEach {
            let content = """
              protocol A {}
              protocol B {}
              protocol C {}

              class Another: A
              ,B, C  {}
              """
            
            self.fileURL = try? Temporary.makeFile(content: content)
            let sut = TypeConformanceAnalyzer(typeName: "B")
            result = try? sut.analyze(fileURL: self.fileURL)
          }
          
          it("conforms") {
            expect(result?.doesConform) == true
          }
          
          it("returns the conforming type name") {
            expect(result?.conformingTypeNames) == ["Another"]
          }
        }
      }
      
      context("when a type implements a subclass") {
        beforeEach {
          let content = """
          open class Some {}

          class Another: Some {}
          """
          
          self.fileURL = try? Temporary.makeFile(content: content)
          let sut = TypeConformanceAnalyzer(typeName: "Some")
          result = try? sut.analyze(fileURL: self.fileURL)
        }
        
        it("is marked as conforms") {
          expect(result?.doesConform) == true
        }
        
        it("returns the conforming type name") {
          expect(result?.conformingTypeNames) == ["Another"]
        }
      }
      
      context("when the type is not present") {
        beforeEach {
          let content = """
          protocol Some {}

          class Another: Some {}
          """
          
          self.fileURL = try? Temporary.makeFile(content: content)
          let sut = TypeConformanceAnalyzer(typeName: "AnotherType")
          result = try? sut.analyze(fileURL: self.fileURL)
        }
        
        it("is not marked as conforms") {
          expect(result?.doesConform) == false
        }
        
        it("returns an empty array for conforming types") {
          expect(result?.conformingTypeNames) == []
        }
      }
      
    }
  }
  
}
