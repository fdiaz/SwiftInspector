// Created by Francisco Diaz on 3/11/20.
// Copyright © 2020 Airbnb Inc. All rights reserved.

import ArgumentParser

struct InspectorCommand: ParsableCommand {
  static var configuration = CommandConfiguration(
    commandName: "SwiftInspector",
    abstract: "A command line tool to help inspect usage of classes, protocols, properties, etc in a Swift codebase.",
    subcommands: [StaticUsageCommand.self, TypeConformanceCommand.self])
}
