// Created by Dan Federman on 1/29/21.
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

final class NestableTypeVisitorSpec: QuickSpec {
  private var sut = NestableTypeVisitor()

  override func spec() {
    beforeEach {
      self.sut = NestableTypeVisitor()
    }

    describe("visit(_:)") {
      context("visiting a single top-level declaration") {
        context("that is a class") {
          context("with no conformance") {
            beforeEach {
              let content = """
                public class SomeClass {}
                """

              try? VisitorExecutor.walkVisitor(
                self.sut,
                overContent: content)
            }

            it("finds the type name") {
              let classInfo = self.sut.classes.first
              expect(classInfo?.name) == "SomeClass"
              expect(classInfo?.inheritsFromTypes.map { $0.asSource }) == []
              expect(classInfo?.parentType).to(beNil())
            }

            it("does not find a struct") {
              expect(self.sut.structs.count) == 0
            }

            it("does not find an enum") {
              expect(self.sut.enums.count) == 0
            }
          }

          context("with a single generic") {
            it("finds the generic name") {
              let content = """
                public class SomeClass<T> {}
                """

              try VisitorExecutor.walkVisitor(
                self.sut,
                overContent: content)

              let classInfo = self.sut.classes.first
              expect(classInfo?.name) == "SomeClass"
              expect(classInfo?.genericParameters.map { $0.name }) == ["T"]
            }
          }

          context("with a single type conformance") {
            it("finds the type name") {
              let content = """
                public class SomeClass: Equatable {}
                """

              try VisitorExecutor.walkVisitor(
                self.sut,
                overContent: content)

              let classInfo = self.sut.classes.first
              expect(classInfo?.name) == "SomeClass"
              expect(classInfo?.inheritsFromTypes.map { $0.asSource }) == ["Equatable"]
              expect(classInfo?.parentType).to(beNil())
            }
          }

          context("with multiple type conformances") {
            it("finds the type name") {
              let content = """
                public class SomeClass: Foo, Bar {}
                """

              try VisitorExecutor.walkVisitor(
                self.sut,
                overContent: content)

              let classInfo = self.sut.classes.first
              expect(classInfo?.name) == "SomeClass"
              expect(classInfo?.inheritsFromTypes.map { $0.asSource }) == ["Foo", "Bar"]
              expect(classInfo?.parentType).to(beNil())
            }
          }

          context("with a typealias") {
            beforeEach {
              let content = """
                public class SomeClass {
                  typealias MyString = String
                }
                """

              try? VisitorExecutor.walkVisitor(
                self.sut,
                overContent: content)
            }

            it("finds the typealias") {
              let typealiasInfo = self.sut.typealiases.first
              expect(typealiasInfo?.name) == "MyString"
              expect(typealiasInfo?.initializer?.asSource) == "String"
            }
          }
        }

        context("that is a struct") {
          context("with no conformance") {
            beforeEach {
              let content = """
                public struct SomeStruct {}
                """

              try? VisitorExecutor.walkVisitor(
                self.sut,
                overContent: content)
            }

            it("finds the type name") {
              let structInfo = self.sut.structs.first
              expect(structInfo?.name) == "SomeStruct"
              expect(structInfo?.inheritsFromTypes.map { $0.asSource }) == []
              expect(structInfo?.parentType).to(beNil())
            }

            it("does not find a class") {
              expect(self.sut.classes.count) == 0
            }

            it("does not find an enum") {
              expect(self.sut.enums.count) == 0
            }
          }

          context("with a single generic") {
            it("finds the generic name") {
              let content = """
                public struct SomeStruct<T> {}
                """

              try VisitorExecutor.walkVisitor(
                self.sut,
                overContent: content)

              let structInfo = self.sut.structs.first
              expect(structInfo?.name) == "SomeStruct"
              expect(structInfo?.genericParameters.map { $0.name }) == ["T"]
            }
          }

          context("with a single type conformance") {
            it("finds the type name") {
              let content = """
                public struct SomeStruct: Equatable {}
                """

              try VisitorExecutor.walkVisitor(
                self.sut,
                overContent: content)

              let structInfo = self.sut.structs.first
              expect(structInfo?.name) == "SomeStruct"
              expect(structInfo?.inheritsFromTypes.map { $0.asSource }) == ["Equatable"]
              expect(structInfo?.parentType).to(beNil())
            }
          }

          context("with multiple type conformances") {
            it("finds the type name") {
              let content = """
                public struct SomeStruct: Foo, Bar {}
                """

              try VisitorExecutor.walkVisitor(
                self.sut,
                overContent: content)

              let structInfo = self.sut.structs.first
              expect(structInfo?.name) == "SomeStruct"
              expect(structInfo?.inheritsFromTypes.map { $0.asSource }) == ["Foo", "Bar"]
              expect(structInfo?.parentType).to(beNil())
            }
          }

          context("with a typealias") {
            beforeEach {
              let content = """
                public enum SomeEnum {
                  typealias MyString = String
                }
                """

              try? VisitorExecutor.walkVisitor(
                self.sut,
                overContent: content)
            }

            it("finds the typealias") {
              let typealiasInfo = self.sut.typealiases.first
              expect(typealiasInfo?.name) == "MyString"
              expect(typealiasInfo?.initializer?.asSource) == "String"
            }
          }
        }

        context("that is an enum") {
          context("with no conformance") {
            beforeEach {
              let content = """
              public enum SomeEnum {}
              """

              try? VisitorExecutor.walkVisitor(
                self.sut,
                overContent: content)
            }

            it("finds the type name") {
              let classInfo = self.sut.enums.first
              expect(classInfo?.name) == "SomeEnum"
              expect(classInfo?.inheritsFromTypes.map { $0.asSource }) == []
              expect(classInfo?.parentType).to(beNil())
            }

            it("does not find a class") {
              expect(self.sut.classes.count) == 0
            }

            it("does not find a struct") {
              expect(self.sut.structs.count) == 0
            }
          }

          context("with a single generic") {
            it("finds the generic name") {
              let content = """
                public enum SomeEnum<T> {}
                """

              try VisitorExecutor.walkVisitor(
                self.sut,
                overContent: content)

              let enumsInfo = self.sut.enums.first
              expect(enumsInfo?.name) == "SomeEnum"
              expect(enumsInfo?.genericParameters.map { $0.name }) == ["T"]
            }
          }

          context("with a single type conformance") {
            it("finds the type name") {
              let content = """
              public enum SomeEnum: Equatable {}
              """

              try VisitorExecutor.walkVisitor(
                self.sut,
                overContent: content)

              let classInfo = self.sut.enums.first
              expect(classInfo?.name) == "SomeEnum"
              expect(classInfo?.inheritsFromTypes.map { $0.asSource }) == ["Equatable"]
              expect(classInfo?.parentType).to(beNil())
            }
          }

          context("with multiple type conformances") {
            it("finds the type name") {
              let content = """
              public enum SomeEnum: Foo, Bar {}
              """

              try VisitorExecutor.walkVisitor(
                self.sut,
                overContent: content)

              let classInfo = self.sut.enums.first
              expect(classInfo?.name) == "SomeEnum"
              expect(classInfo?.inheritsFromTypes.map { $0.asSource }) == ["Foo", "Bar"]
              expect(classInfo?.parentType).to(beNil())
            }
          }

          context("with a typealias") {
            beforeEach {
              let content = """
                public enum SomeEnum {
                  typealias MyString = String
                }
                """

              try? VisitorExecutor.walkVisitor(
                self.sut,
                overContent: content)
            }

            it("finds the typealias") {
              let typealiasInfo = self.sut.typealiases.first
              expect(typealiasInfo?.name) == "MyString"
              expect(typealiasInfo?.initializer?.asSource) == "String"
            }
          }
        }
      }

      context("visiting a code block with nested declarations") {
        context("visiting a class with nested classes") {
          beforeEach {
            let content = """
              public class FooClass {
                internal class FooClass {}
                public class BarFooClass: Equatable {
                  public class BarBarFooClass: Hashable {}
                }
                public class FooFooClass {
                  public class BarFooFoo1Class: BarFooFoo1Protocol1,
                    BarFooFoo1Protocol2
                  {
                    public class BarBarFooFoo1Class {}
                  }
                  public class BarFooFoo2Class {}
                }
              }
              """

            try? VisitorExecutor.walkVisitor(
              self.sut,
              overContent: content)
          }

          it("finds FooClass") {
            let matching = self.sut.classes.filter {
              $0.name == "FooClass"
                && $0.inheritsFromTypes.map { $0.asSource } == []
                && $0.parentType?.asSource == nil
                && $0.modifiers.contains("public")
            }

            expect(matching.count) == 1
          }

          it("finds FooClass.FooClass") {
            let matching = self.sut.classes.filter {
              $0.name == "FooClass"
                && $0.inheritsFromTypes.map { $0.asSource } == []
                && $0.parentType?.asSource == "FooClass"
                && $0.modifiers.contains("internal")
            }

            expect(matching.count) == 1
          }

          it("finds BarFooClass") {
            let matching = self.sut.classes.filter {
              $0.name == "BarFooClass"
                && $0.inheritsFromTypes.map { $0.asSource } == ["Equatable"]
                && $0.parentType?.asSource == "FooClass"
            }

            expect(matching.count) == 1
          }

          it("finds BarBarFooClass") {
            let matching = self.sut.classes.filter {
              $0.name == "BarBarFooClass"
                && $0.inheritsFromTypes.map { $0.asSource } == ["Hashable"]
                && $0.parentType?.asSource == "FooClass.BarFooClass"
            }

            expect(matching.count) == 1
          }

          it("finds FooFooClass") {
            let matching = self.sut.classes.filter {
              $0.name == "FooFooClass"
                && $0.inheritsFromTypes.map { $0.asSource } == []
                && $0.parentType?.asSource == "FooClass"
            }

            expect(matching.count) == 1
          }

          it("finds BarFooFoo1Class") {
            let matching = self.sut.classes.filter {
              $0.name == "BarFooFoo1Class"
                && $0.inheritsFromTypes.map { $0.asSource } == ["BarFooFoo1Protocol1", "BarFooFoo1Protocol2"]
                && $0.parentType?.asSource == "FooClass.FooFooClass"
            }

            expect(matching.count) == 1
          }

          it("finds BarBarFooFoo1Class") {
            let matching = self.sut.classes.filter {
              $0.name == "BarBarFooFoo1Class"
                && $0.inheritsFromTypes.map { $0.asSource } == []
                && $0.parentType?.asSource == "FooClass.FooFooClass.BarFooFoo1Class"
            }

            expect(matching.count) == 1
          }

          it("finds BarFooFoo2Class") {
            let matching = self.sut.classes.filter {
              $0.name == "BarFooFoo2Class"
                && $0.inheritsFromTypes.map { $0.asSource } == []
                && $0.parentType?.asSource == "FooClass.FooFooClass"
            }

            expect(matching.count) == 1
          }
        }

        context("visiting a struct with nested structs") {
          beforeEach {
            let content = """
              public struct FooStruct {
                internal struct BarFooStruct: Equatable {
                  public struct BarBarFooStruct: Hashable {}
                }
                public struct FooFooStruct {
                  public struct BarFooFoo1Struct: BarFooFoo1Protocol1,
                    BarFooFoo1Protocol2
                  {
                    public struct BarBarFooFoo1Struct {}
                  }
                  public struct BarFooFoo2Struct {}
                }
              }
              """

            try? VisitorExecutor.walkVisitor(
              self.sut,
              overContent: content)
          }

          it("finds FooStruct") {
            let matching = self.sut.structs.filter {
              $0.name == "FooStruct"
                && $0.inheritsFromTypes.map { $0.asSource } == []
                && $0.parentType?.asSource == nil
                && $0.modifiers == .init(["public"])
            }

            expect(matching.count) == 1
          }

          it("finds BarFooStruct") {
            let matching = self.sut.structs.filter {
              $0.name == "BarFooStruct"
                && $0.inheritsFromTypes.map { $0.asSource } == ["Equatable"]
                && $0.parentType?.asSource == "FooStruct"
                && $0.modifiers == .init(["internal"])
            }

            expect(matching.count) == 1
          }

          it("finds BarBarFooStruct") {
            let matching = self.sut.structs.filter {
              $0.name == "BarBarFooStruct"
                && $0.inheritsFromTypes.map { $0.asSource } == ["Hashable"]
                && $0.parentType?.asSource == "FooStruct.BarFooStruct"
            }

            expect(matching.count) == 1
          }

          it("finds FooFooStruct") {
            let matching = self.sut.structs.filter {
              $0.name == "FooFooStruct"
                && $0.inheritsFromTypes.map { $0.asSource } == []
                && $0.parentType?.asSource == "FooStruct"
            }

            expect(matching.count) == 1
          }

          it("finds BarFooFoo1Struct") {
            let matching = self.sut.structs.filter {
              $0.name == "BarFooFoo1Struct"
                && $0.inheritsFromTypes.map { $0.asSource } == ["BarFooFoo1Protocol1", "BarFooFoo1Protocol2"]
                && $0.parentType?.asSource == "FooStruct.FooFooStruct"
            }

            expect(matching.count) == 1
          }

          it("finds BarBarFooFoo1Struct") {
            let matching = self.sut.structs.filter {
              $0.name == "BarBarFooFoo1Struct"
                && $0.inheritsFromTypes.map { $0.asSource } == []
                && $0.parentType?.asSource == "FooStruct.FooFooStruct.BarFooFoo1Struct"
            }

            expect(matching.count) == 1
          }

          it("finds BarFooFoo2Struct") {
            let matching = self.sut.structs.filter {
              $0.name == "BarFooFoo2Struct"
                && $0.inheritsFromTypes.map { $0.asSource } == []
                && $0.parentType?.asSource == "FooStruct.FooFooStruct"
            }

            expect(matching.count) == 1
          }
        }

        context("visiting a enum with nested enums") {
          beforeEach {
            let content = """
              public enum FooEnum {
                internal enum BarFooEnum: Equatable {
                  public enum BarBarFooEnum: Hashable {}
                }
                public enum FooFooEnum {
                  public enum BarFooFoo1Enum: BarFooFoo1Protocol1,
                    BarFooFoo1Protocol2
                  {
                    public enum BarBarFooFoo1Enum {}
                  }
                  public enum BarFooFoo2Enum {}
                }
              }
              """

            try? VisitorExecutor.walkVisitor(
              self.sut,
              overContent: content)
          }

          it("finds FooEnum") {
            let matching = self.sut.enums.filter {
              $0.name == "FooEnum"
                && $0.inheritsFromTypes.map { $0.asSource } == []
                && $0.parentType?.asSource == nil
                && $0.modifiers.contains("public")
            }
            expect(matching.count) == 1
          }

          it("finds BarFooEnum") {
            let matching = self.sut.enums.filter {
              $0.name == "BarFooEnum"
                && $0.inheritsFromTypes.map { $0.asSource } == ["Equatable"]
                && $0.parentType?.asSource == "FooEnum"
                && $0.modifiers.contains("internal")
            }
            expect(matching.count) == 1
          }

          it("finds BarBarFooEnum") {
            let matching = self.sut.enums.filter {
              $0.name == "BarBarFooEnum"
                && $0.inheritsFromTypes.map { $0.asSource } == ["Hashable"]
                && $0.parentType?.asSource == "FooEnum.BarFooEnum"
            }
            expect(matching.count) == 1
          }

          it("finds FooFooEnum") {
            let matching = self.sut.enums.filter {
              $0.name == "FooFooEnum"
                && $0.inheritsFromTypes.map { $0.asSource } == []
                && $0.parentType?.asSource == "FooEnum"
            }
            expect(matching.count) == 1
          }

          it("finds BarFooFoo1Enum") {
            let matching = self.sut.enums.filter {
              $0.name == "BarFooFoo1Enum"
                && $0.inheritsFromTypes.map { $0.asSource } == ["BarFooFoo1Protocol1", "BarFooFoo1Protocol2"]
                && $0.parentType?.asSource == "FooEnum.FooFooEnum"
            }
            expect(matching.count) == 1
          }

          it("finds BarBarFooFoo1Enum") {
            let matching = self.sut.enums.filter {
              $0.name == "BarBarFooFoo1Enum"
                && $0.inheritsFromTypes.map { $0.asSource } == []
                && $0.parentType?.asSource == "FooEnum.FooFooEnum.BarFooFoo1Enum"
            }
            expect(matching.count) == 1
          }

          it("finds BarFooFoo2Enum") {
            let matching = self.sut.enums.filter {
              $0.name == "BarFooFoo2Enum"
                && $0.inheritsFromTypes.map { $0.asSource } == []
                && $0.parentType?.asSource == "FooEnum.FooFooEnum"
            }
            expect(matching.count) == 1
          }
        }

        context("visiting a class with nested structs, classes, enums, and typealiases") {
          beforeEach {
            let content = """
              public class FooClass {
                public struct BarFooStruct: Equatable {
                  public class BarBarFooClass {}
                  public typealias BarBarFooTypealias = Void
                }
                public enum BarFooEnum {
                  public class BarBarFooClass {}
                }
                public class FooFooClass {
                  public class BarFooFooClass {}
                }
              }
              """

            try? VisitorExecutor.walkVisitor(
              self.sut,
              overContent: content)
          }

          it("finds FooClass") {
            let matching = self.sut.classes.filter {
              $0.name == "FooClass"
                && $0.inheritsFromTypes.map { $0.asSource } == []
                && $0.parentType?.asSource == nil
            }

            expect(matching.count) == 1
          }

          it("finds FooClass.BarFooStruct") {
            let matching = self.sut.structs.filter {
              $0.name == "BarFooStruct"
                && $0.inheritsFromTypes.map { $0.asSource } == ["Equatable"]
                && $0.parentType?.asSource == "FooClass"
            }

            expect(matching.count) == 1
          }

          it("finds FooClass.BarFooStruct.BarBarFooClass") {
            let matching = self.sut.classes.filter {
              $0.name == "BarBarFooClass"
                && $0.inheritsFromTypes.map { $0.asSource } == []
                && $0.parentType?.asSource == "FooClass.BarFooStruct"
            }

            expect(matching.count) == 1
          }

          it("finds FooClass.BarFooStruct.BarBarFooTypealias") {
            let matching = self.sut.typealiases.filter {
              $0.name == "BarBarFooTypealias"
                && $0.initializer?.asSource == "Void"
                && $0.parentType?.asSource == "FooClass.BarFooStruct"
            }
            expect(matching.count) == 1
          }

          it("finds FooClass.FooFooClass") {
            let matching = self.sut.classes.filter {
              $0.name == "FooFooClass"
                && $0.inheritsFromTypes.map { $0.asSource } == []
                && $0.parentType?.asSource == "FooClass"
            }

            expect(matching.count) == 1
          }

          it("finds FooClass.FooFooClass.BarFooFooClass") {
            let matching = self.sut.classes.filter {
              $0.name == "BarFooFooClass"
                && $0.inheritsFromTypes.map { $0.asSource } == []
                && $0.parentType?.asSource == "FooClass.FooFooClass"
            }

            expect(matching.count) == 1
          }

          it("finds FooClass.BarFooEnum") {
            let matching = self.sut.enums.filter {
              $0.name == "BarFooEnum"
                && $0.inheritsFromTypes.map { $0.asSource } == []
                && $0.parentType?.asSource == "FooClass"
            }

            expect(matching.count) == 1
          }

          it("finds FooClass.BarFooEnum.BarBarFooClass") {
            let matching = self.sut.classes.filter {
              $0.name == "BarBarFooClass"
                && $0.inheritsFromTypes.map { $0.asSource } == []
                && $0.parentType?.asSource == "FooClass.BarFooEnum"
            }

            expect(matching.count) == 1
          }
        }

        context("visiting a struct with nested structs, classes, enums, and typealiases") {
          beforeEach {
            let content = """
              public struct FooStruct {
                public struct FooStruct {}
                public class BarFooClass: Equatable {
                  public struct BarBarFooStruct {}
                  public typealias BarBarFooTypealias = Void
                }
                public enum BarFooEnum {
                  public struct BarBarFooStruct {}
                }
                public struct FooFooStruct {
                  public struct BarFooFooStruct {}
                }
              }
              """

            try? VisitorExecutor.walkVisitor(
              self.sut,
              overContent: content)
          }

          it("finds FooStruct") {
            let matching = self.sut.structs.filter {
              $0.name == "FooStruct"
                && $0.inheritsFromTypes.map { $0.asSource } == []
                && $0.parentType?.asSource == nil
            }

            expect(matching.count) == 1
          }

          it("finds FooStruct.FooStruct") {
            let matching = self.sut.structs.filter {
              $0.name == "FooStruct"
                && $0.inheritsFromTypes.map { $0.asSource } == []
                && $0.parentType?.asSource == "FooStruct"
            }

            expect(matching.count) == 1
          }

          it("finds FooStruct.FooFooStruct") {
            let matching = self.sut.structs.filter {
              $0.name == "FooFooStruct"
                && $0.inheritsFromTypes.map { $0.asSource } == []
                && $0.parentType?.asSource == "FooStruct"
            }

            expect(matching.count) == 1
          }

          it("finds FooStruct.FooFooStruct.BarFooFooStruct") {
            let matching = self.sut.structs.filter {
              $0.name == "BarFooFooStruct"
                && $0.inheritsFromTypes.map { $0.asSource } == []
                && $0.parentType?.asSource == "FooStruct.FooFooStruct"
            }

            expect(matching.count) == 1
          }

          it("finds FooStruct.BarFooClass") {
            let matching = self.sut.classes.filter {
              $0.name == "BarFooClass"
                && $0.inheritsFromTypes.map { $0.asSource } == ["Equatable"]
                && $0.parentType?.asSource == "FooStruct"
            }

            expect(matching.count) == 1
          }

          it("finds FooStruct.BarFooClass.BarBarFooStruct") {
            let matching = self.sut.structs.filter {
              $0.name == "BarBarFooStruct"
                && $0.inheritsFromTypes.map { $0.asSource } == []
                && $0.parentType?.asSource == "FooStruct.BarFooClass"
            }

            expect(matching.count) == 1
          }

          it("finds FooStruct.BarFooClass.BarBarFooTypealias") {
            let matching = self.sut.typealiases.filter {
              $0.name == "BarBarFooTypealias"
                && $0.initializer?.asSource == "Void"
                && $0.parentType?.asSource == "FooStruct.BarFooClass"
            }
            expect(matching.count) == 1
          }

          it("finds FooStruct.BarFooEnum") {
            let matching = self.sut.enums.filter {
              $0.name == "BarFooEnum"
                && $0.inheritsFromTypes.map { $0.asSource } == []
                && $0.parentType?.asSource == "FooStruct"
            }

            expect(matching.count) == 1
          }

          it("finds FooStruct.BarFooEnum.BarBarFooStruct") {
            let matching = self.sut.structs.filter {
              $0.name == "BarBarFooStruct"
                && $0.inheritsFromTypes.map { $0.asSource } == []
                && $0.parentType?.asSource == "FooStruct.BarFooEnum"
            }

            expect(matching.count) == 1
          }
        }
      }

      context("visiting an enum with nested structs, classes, enums, and typealiases") {
        beforeEach {
          let content = """
              public enum FooEnum {
                public enum FooEnum {}
                public struct BarFooStruct {
                  public enum BarBarFooEnum {}
                  public typealias BarBarFooTypealias = Void
                }
                public enum BarFooEnum: Equatable {
                  public enum BarBarFooEnum {}
                }
                public class FooFooClass {
                  public enum BarFooFooEnum {}
                }
              }
              """

          try? VisitorExecutor.walkVisitor(
            self.sut,
            overContent: content)
        }

        it("finds FooEnum") {
          let matching = self.sut.enums.filter {
            $0.name == "FooEnum"
              && $0.inheritsFromTypes.map { $0.asSource } == []
              && $0.parentType?.asSource == nil
          }
          expect(matching.count) == 1
        }

        it("finds FooEnum.FooEnum") {
          let matching = self.sut.enums.filter {
            $0.name == "FooEnum"
              && $0.inheritsFromTypes.map { $0.asSource } == []
              && $0.parentType?.asSource == "FooEnum"
          }
          expect(matching.count) == 1
        }

        it("finds FooEnum.BarFooStruct") {
          let matching = self.sut.structs.filter {
            $0.name == "BarFooStruct"
              && $0.inheritsFromTypes.map { $0.asSource } == []
              && $0.parentType?.asSource == "FooEnum"
          }
          expect(matching.count) == 1
        }

        it("finds FooEnum.BarFooEnum") {
          let matching = self.sut.enums.filter {
            $0.name == "BarFooEnum"
              && $0.inheritsFromTypes.map { $0.asSource } == ["Equatable"]
              && $0.parentType?.asSource == "FooEnum"
          }
          expect(matching.count) == 1
        }

        it("finds FooEnum.BarFooEnum.BarBarFooEnum") {
          let matching = self.sut.enums.filter {
            $0.name == "BarBarFooEnum"
              && $0.inheritsFromTypes.map { $0.asSource } == []
              && $0.parentType?.asSource == "FooEnum.BarFooEnum"
          }
          expect(matching.count) == 1
        }

        it("finds FooEnum.BarFooStruct.BarBarFooEnum") {
          let matching = self.sut.enums.filter {
            $0.name == "BarBarFooEnum"
              && $0.inheritsFromTypes.map { $0.asSource } == []
              && $0.parentType?.asSource == "FooEnum.BarFooStruct"
          }
          expect(matching.count) == 1
        }

        it("finds FooEnum.BarFooStruct.BarBarFooTypealias") {
          let matching = self.sut.typealiases.filter {
            $0.name == "BarBarFooTypealias"
              && $0.initializer?.asSource == "Void"
              && $0.parentType?.asSource == "FooEnum.BarFooStruct"
          }
          expect(matching.count) == 1
        }

        it("finds FooEnum.FooFooClass") {
          let matching = self.sut.classes.filter {
            $0.name == "FooFooClass"
              && $0.inheritsFromTypes.map { $0.asSource } == []
              && $0.parentType?.asSource == "FooEnum"
          }
          expect(matching.count) == 1
        }

        it("finds FooEnum.FooFooClass.BarFooFooEnum") {
          let matching = self.sut.enums.filter {
            $0.name == "BarFooFooEnum"
              && $0.inheritsFromTypes.map { $0.asSource } == []
              && $0.parentType?.asSource == "FooEnum.FooFooClass"
          }
          expect(matching.count) == 1
        }
      }
    }

    context("visiting a code block with multiple top-level declarations") {
      context("with a top-level declaration after a top-level class") {
        context("with a top-level class declaration") {
          it("asserts") {
            let content = """
          public class FooClass {}
          public class BarClass {}
          """

            // The ClassVisitor is only meant to be used over a single class.
            // Using a ClassVisitor over a block that has multiple top-level
            // classes is API misuse.
            expect(try VisitorExecutor.walkVisitor(
                    self.sut,
                    overContent: content))
              .to(throwAssertion())
          }
        }

        context("with a top-level struct declaration") {
          it("asserts") {
            let content = """
          public class FooClass {}
          public struct FooStruct {}
          """

            // The ClassVisitor is only meant to be used over a single class.
            // Using a ClassVisitor over a block that has a top-level struct
            // is API misuse.
            expect(try VisitorExecutor.walkVisitor(
                    self.sut,
                    overContent: content))
              .to(throwAssertion())
          }
        }

        context("with a top-level enum declaration") {
          it("asserts") {
            let content = """
          public class FooClass {}
          public struct FooEnum {}
          """

            // The ClassVisitor is only meant to be used over a single class.
            // Using a ClassVisitor over a block that has a top-level enum
            // is API misuse.
            expect(try VisitorExecutor.walkVisitor(
                    self.sut,
                    overContent: content))
              .to(throwAssertion())
          }
        }
      }

      context("with a top-level declaration after a top-level struct") {
        context("with a top-level struct declaration") {
          it("asserts") {
            let content = """
          public struct FooStruct {}
          public struct BarStruct {}
          """

            // The NestableTypeVisitor is only meant to be used over a single nestable type.
            // Using a NestableTypeVisitor over a block that has multiple top-level
            // structs is API misuse.
            expect(try VisitorExecutor.walkVisitor(
                    self.sut,
                    overContent: content))
              .to(throwAssertion())
          }
        }

        context("with a top-level class declaration") {
          it("asserts") {
            let content = """
          public struct FooStruct {}
          public class FooClass {}
          """

            // The NestableTypeVisitor is only meant to be used over a single nestable type.
            // Using a NestableTypeVisitor over a block that has a top-level class
            // is API misuse.
            expect(try VisitorExecutor.walkVisitor(
                    self.sut,
                    overContent: content))
              .to(throwAssertion())
          }
        }

        context("with a top-level enum declaration") {
          it("asserts") {
            let content = """
          public struct FooStruct {}
          public struct FooEnum {}
          """

            // The NestableTypeVisitor is only meant to be used over a single nestable type.
            // Using a NestableTypeVisitor over a block that has a top-level enum
            // is API misuse.
            expect(try VisitorExecutor.walkVisitor(
                    self.sut,
                    overContent: content))
              .to(throwAssertion())
          }
        }
      }

      context("with a top-level declaration after a top-level enum") {
        context("with a top-level enum declaration") {
          it("asserts") {
            let content = """
            public enum FooEnum {}
            public enum BarEnum {}
            """

            // The NestableTypeVisitor is only meant to be used over a single nestable type.
            // Using a NestableTypeVisitor over a block that has multiple top-level
            // classes is API misuse.
            expect(try VisitorExecutor.walkVisitor(
                    self.sut,
                    overContent: content))
              .to(throwAssertion())
          }
        }

        context("with a top-level struct declaration") {
          it("asserts") {
            let content = """
            public enum FooEnum {}
            public struct FooStruct {}
            """

            // The NestableTypeVisitor is only meant to be used over a single nestable type.
            // Using a NestableTypeVisitor over a block that has a top-level struct
            // is API misuse.
            expect(try VisitorExecutor.walkVisitor(
                    self.sut,
                    overContent: content))
              .to(throwAssertion())
          }
        }

        context("with a top-level class declaration") {
          it("asserts") {
            let content = """
            public enum FooEnum {}
            public class FooClass {}
            """

            // The NestableTypeVisitor is only meant to be used over a single nestable type.
            // Using a NestableTypeVisitor over a block that has a top-level class
            // is API misuse.
            expect(try VisitorExecutor.walkVisitor(
                    self.sut,
                    overContent: content))
              .to(throwAssertion())
          }
        }
      }
    }

    context("visiting a code block with a protocol declaration") {
      it("asserts") {
        let content = """
            public protocol FooProtocol {}
            """

        // The NestableTypeVisitor is only meant to be used over a single nestable type.
        // Using a NestableTypeVisitor over a block that has a top-level protocol
        // is API misuse.
        expect(try VisitorExecutor.walkVisitor(
                self.sut,
                overContent: content))
          .to(throwAssertion())
      }
    }

    context("visiting a code block with an extension declaration") {
      it("asserts") {
        let content = """
            public extension Array {}
            """

        // The NestableTypeVisitor is only meant to be used over a single nestable type.
        // Using a NestableTypeVisitor over a block that has an extension
        // is API misuse.
        expect(try VisitorExecutor.walkVisitor(
                self.sut,
                overContent: content))
          .to(throwAssertion())
      }
    }

    context("visiting a code block with a top-level typealias") {
      it("asserts") {
        let content = """
            public typealias Sad = Void
            """

        // The NestableTypeVisitor is only meant to be used over a single nestable type.
        // Using a NestableTypeVisitor over a block that has a top-level typealias
        // is API misuse.
        expect(try VisitorExecutor.walkVisitor(
                self.sut,
                overContent: content))
          .to(throwAssertion())
      }
    }
  }
}
