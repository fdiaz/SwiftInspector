// Created by Francisco Diaz on 10/11/19.
// Copyright © 2019 Airbnb Inc. All rights reserved.

import Commandant
import Foundation
import SwiftInspectorKit
import Nimble
import Quick

final class TypeConformanceCommandSpec: QuickSpec {
  var registry: CommandRegistry<Error>!
  var sut: TypeConformanceCommand!

  override func spec() {
    beforeEach {
      self.sut = TypeConformanceCommand()
      self.registry = CommandRegistry<Error>()
      self.registry.register(self.sut)
    }

    describe("run") {
      context("with no arguments") {
        it("fails") {
          let result = self.registry.run(command: self.sut.verb, arguments: [])
          expect { try result?.get() }.to(throwError())
        }
      }

      context("with no --type-name argument") {
        it("fails") {
          let result = self.registry.run(command: self.sut.verb, arguments: ["--path", "."])
          expect { try result?.get() }.to(throwError())
        }
      }

      context("with an empty --type-name argument") {
        it("fails") {
          let result = self.registry.run(command: self.sut.verb, arguments: ["--type-name", "", "--path", "/abc"])
          expect { try result?.get() }.to(throwError())
        }
      }

      context("with no --path argument") {
        it("fails") {
          let result = self.registry.run(command: self.sut.verb, arguments: ["--type-name", "SomeType"])
          expect { try result?.get() }.to(throwError())
        }
      }

      context("with an empty --path argument") {
        it("fails") {
          let result = self.registry.run(command: self.sut.verb, arguments: ["--type-name", "SomeType", "--path", ""])
          expect { try result?.get() }.to(throwError())
        }
      }

      context("with all arguments") {
        it("succeeds") {
          let result = self.registry.run(command: self.sut.verb, arguments: ["--type-name", "SomeType", "--path", "/abc"])
          expect { try result?.get() }.toNot(throwError())
        }
      }
    }
  }
}
