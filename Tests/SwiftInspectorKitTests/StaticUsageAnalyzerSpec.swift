// Created by Francisco Diaz on 10/16/19.
//
//  Copyright (c) 2020 Francisco Diaz
//
//  Distributed under the MIT License
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.

import Nimble
import Quick
import Foundation

@testable import SwiftInspectorKit

final class StaticUsageAnalyzerSpec: QuickSpec {
  private var fileURL: URL!

  override func spec() {
    afterEach {
      guard let fileURL = self.fileURL else {
        return
      }
      try? Temporary.removeItem(at: fileURL)
    }

    describe("analyze(fileURL:)") {
      context("when accessing a static property directly") {
        it("marks the staticMember as used") {
          let content = "DeepLinkRouter.shared"
          self.fileURL = try? Temporary.makeFile(content: content, name: "ABC")

          let staticMember = StaticMember(typeName: "DeepLinkRouter", memberName: "shared")
          let sut = StaticUsageAnalyzer(staticMember: staticMember)
          let result = try? sut.analyze(fileURL: self.fileURL)

          expect(result?.staticMember) == staticMember
          expect(result?.isUsed) == true
        }

        context("and the staticMember is divided in multiple lines") {
          it("marks the staticMember as used") {
            let content = """
            final class Some {
              let router = DeepLinkRouter
                           .shared
            }
            """
            self.fileURL = try? Temporary.makeFile(content: content, name: "ABC")

            let staticMember = StaticMember(typeName: "DeepLinkRouter", memberName: "shared")
            let sut = StaticUsageAnalyzer(staticMember: staticMember)
            let result = try? sut.analyze(fileURL: self.fileURL)

            expect(result?.staticMember) == staticMember
            expect(result?.isUsed) == true
          }
        }

        context("when the type name is not present") {
          it("marks the staticMember as not used") {
            let content = "DeepLinkRouter.shared"
            self.fileURL = try? Temporary.makeFile(content: content, name: "ABC")

            let staticMember = StaticMember(typeName: "SomeOtherType", memberName: "shared")
            let sut = StaticUsageAnalyzer(staticMember: staticMember)
            let result = try? sut.analyze(fileURL: self.fileURL)

            expect(result?.staticMember) == staticMember
            expect(result?.isUsed) == false
          }
        }

      }
    }

    context("when accessing a method on a static property") {
      it("marks the staticMember as used") {
        let content = "DeprecatedTrebuchetManagingFactory.current!.isLaunched(.someTrebuchet)"
        self.fileURL = try? Temporary.makeFile(content: content, name: "ABC")

        let staticMember = StaticMember(typeName: "DeprecatedTrebuchetManagingFactory", memberName: "current")
        let sut = StaticUsageAnalyzer(staticMember: staticMember)
        let result = try? sut.analyze(fileURL: self.fileURL)

        expect(result?.staticMember) == staticMember
        expect(result?.isUsed) == true
      }
    }

    context("when the staticMember is defined as a method") {
      it("marks the staticMember as used") {
        let content = "BBExperimentManager.sharedInstance()"
        self.fileURL = try? Temporary.makeFile(content: content, name: "ABC")

        let staticMember = StaticMember(typeName: "BBExperimentManager", memberName: "sharedInstance")
        let sut = StaticUsageAnalyzer(staticMember: staticMember)
        let result = try? sut.analyze(fileURL: self.fileURL)

        expect(result?.staticMember) == staticMember
        expect(result?.isUsed) == true
      }
    }

    context("when the staticMember is used in an initializer") {
      it("marks the staticMember as used") {
        let content = """
        DefaultExperimentLauncher(
              trebuchetManager: DeprecatedTrebuchetManagingFactory.current,
              legacyExperimentManager: BBExperimentManager.sharedInstance(),
              keyValueStore: UserDefaults.standard),
              localeService: LocaleServiceObjCAdapter.shared.localeService),
        """
        self.fileURL = try? Temporary.makeFile(content: content, name: "ABC")

        let staticMember = StaticMember(typeName: "DeprecatedTrebuchetManagingFactory", memberName: "current")
        let sut = StaticUsageAnalyzer(staticMember: staticMember)
        let result = try? sut.analyze(fileURL: self.fileURL)

        expect(result?.staticMember) == staticMember
        expect(result?.isUsed) == true
      }
    }

    context("when the staticMember is used in a member") {
      it("marks the staticMember as used") {
        let content = """
        public class SomeClass {
          private let router = DeepLinkRouter.shared
        }
        """
        self.fileURL = try? Temporary.makeFile(content: content, name: "ABC")

        let staticMember = StaticMember(typeName: "DeepLinkRouter", memberName: "shared")
        let sut = StaticUsageAnalyzer(staticMember: staticMember)
        let result = try? sut.analyze(fileURL: self.fileURL)

        expect(result?.staticMember) == staticMember
        expect(result?.isUsed) == true
      }
    }

    context("when the staticMember is used in a method") {
      it("marks the staticMember as used") {
        let content = """
        public class SomeClass {
          fileprivate func updateState() {
            let currentAppVersion = UIApplication.shared.marketingVersion()
            keyValueStore.save(
              currentAppVersion,
              forKey: "LaunchVersion")
          }
        }
        """
        self.fileURL = try? Temporary.makeFile(content: content, name: "ABC")

        let staticMember = StaticMember(typeName: "UIApplication", memberName: "shared")
        let sut = StaticUsageAnalyzer(staticMember: staticMember)
        let result = try? sut.analyze(fileURL: self.fileURL)

        expect(result?.staticMember) == staticMember
        expect(result?.isUsed) == true
      }
    }

    context("when the staticMember is used inside another staticMember usage") {
      it("marks the staticMember as used") {
        let content = """
        JitneyProducer.shared.publish(
              PaidGrowth.V1.PaidGrowthSignupCompletePixelEvent(
                // TODO: Use the globalLoggingContext property on an injected LoggingService than accessing a singleton directly.
                context: EventContext.shared.loggingContext(),
                device_id: trackingManager.value(forAirEventsSharedKey: deviceIDParamKey) ?? "",
                user_id: Int64(accountManager.activeAccount?.user.userId ?? "") ?? 0
              )
            )
        """
        self.fileURL = try? Temporary.makeFile(content: content, name: "ABC")

        let staticMember = StaticMember(typeName: "EventContext", memberName: "shared")
        let sut = StaticUsageAnalyzer(staticMember: staticMember)
        let result = try? sut.analyze(fileURL: self.fileURL)

        expect(result?.staticMember) == staticMember
        expect(result?.isUsed) == true
      }
    }

  }
}
