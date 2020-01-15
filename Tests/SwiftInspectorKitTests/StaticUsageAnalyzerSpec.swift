// Created by Francisco Diaz on 10/16/19.
// Copyright © 2019 Airbnb Inc. All rights reserved.

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
          let content = "AirbnbDeepLinkRouter.shared"
          self.fileURL = try? Temporary.makeSwiftFile(content: content, name: "ABC")

          let staticMember = StaticMember(typeName: "AirbnbDeepLinkRouter", memberName: "shared")
          let sut = StaticUsageAnalyzer(staticMember: staticMember)
          let result = try? sut.analyze(fileURL: self.fileURL)

          expect(result) == StaticUsage(staticMember: staticMember, fileName: "ABC.swift", isUsed: true)
        }

        context("and the staticMember is divided in multiple lines") {
          it("marks the staticMember as used") {
            let content = """
            final class Some {
              let router = AirbnbDeepLinkRouter
                           .shared
            }
            """
            self.fileURL = try? Temporary.makeSwiftFile(content: content, name: "ABC")

            let staticMember = StaticMember(typeName: "AirbnbDeepLinkRouter", memberName: "shared")
            let sut = StaticUsageAnalyzer(staticMember: staticMember)
            let result = try? sut.analyze(fileURL: self.fileURL)

            expect(result) == StaticUsage(staticMember: staticMember, fileName: "ABC.swift", isUsed: true)
          }
        }

        context("when the type name is not present") {
          it("marks the staticMember as not used") {
            let content = "AirbnbDeepLinkRouter.shared"
            self.fileURL = try? Temporary.makeSwiftFile(content: content, name: "ABC")

            let staticMember = StaticMember(typeName: "SomeOtherType", memberName: "shared")
            let sut = StaticUsageAnalyzer(staticMember: staticMember)
            let result = try? sut.analyze(fileURL: self.fileURL)

            expect(result) == StaticUsage(staticMember: staticMember, fileName: "ABC.swift", isUsed: false)
          }
        }

      }
    }

    context("when accessing a method on a static property") {
      it("marks the staticMember as used") {
        let content = "DeprecatedTrebuchetManagingFactory.current!.isLaunched(.someTrebuchet)"
        self.fileURL = try? Temporary.makeSwiftFile(content: content, name: "ABC")

        let staticMember = StaticMember(typeName: "DeprecatedTrebuchetManagingFactory", memberName: "current")
        let sut = StaticUsageAnalyzer(staticMember: staticMember)
        let result = try? sut.analyze(fileURL: self.fileURL)

        expect(result) == StaticUsage(staticMember: staticMember, fileName: "ABC.swift", isUsed: true)
      }
    }

    context("when the staticMember is defined as a method") {
      it("marks the staticMember as used") {
        let content = "BBExperimentManager.sharedInstance()"
        self.fileURL = try? Temporary.makeSwiftFile(content: content, name: "ABC")

        let staticMember = StaticMember(typeName: "BBExperimentManager", memberName: "sharedInstance")
        let sut = StaticUsageAnalyzer(staticMember: staticMember)
        let result = try? sut.analyze(fileURL: self.fileURL)

        expect(result) == StaticUsage(staticMember: staticMember, fileName: "ABC.swift", isUsed: true)
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
        self.fileURL = try? Temporary.makeSwiftFile(content: content, name: "ABC")

        let staticMember = StaticMember(typeName: "DeprecatedTrebuchetManagingFactory", memberName: "current")
        let sut = StaticUsageAnalyzer(staticMember: staticMember)
        let result = try? sut.analyze(fileURL: self.fileURL)

        expect(result) == StaticUsage(staticMember: staticMember, fileName: "ABC.swift", isUsed: true)
      }
    }

    context("when the staticMember is used in a member") {
      it("marks the staticMember as used") {
        let content = """
        public class SomeClass {
          private let router = AirbnbDeepLinkRouter.shared
        }
        """
        self.fileURL = try? Temporary.makeSwiftFile(content: content, name: "ABC")

        let staticMember = StaticMember(typeName: "AirbnbDeepLinkRouter", memberName: "shared")
        let sut = StaticUsageAnalyzer(staticMember: staticMember)
        let result = try? sut.analyze(fileURL: self.fileURL)

        expect(result) == StaticUsage(staticMember: staticMember, fileName: "ABC.swift", isUsed: true)
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
        self.fileURL = try? Temporary.makeSwiftFile(content: content, name: "ABC")

        let staticMember = StaticMember(typeName: "UIApplication", memberName: "shared")
        let sut = StaticUsageAnalyzer(staticMember: staticMember)
        let result = try? sut.analyze(fileURL: self.fileURL)

        expect(result) == StaticUsage(staticMember: staticMember, fileName: "ABC.swift", isUsed: true)
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
        self.fileURL = try? Temporary.makeSwiftFile(content: content, name: "ABC")

        let staticMember = StaticMember(typeName: "EventContext", memberName: "shared")
        let sut = StaticUsageAnalyzer(staticMember: staticMember)
        let result = try? sut.analyze(fileURL: self.fileURL)

        expect(result) == StaticUsage(staticMember: staticMember, fileName: "ABC.swift", isUsed: true)
      }
    }

  }
}
