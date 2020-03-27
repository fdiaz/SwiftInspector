// Created by Francisco Diaz on 3/11/20.
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

import ArgumentParser

public struct InspectorCommand: ParsableCommand {
  public init() {}

  public static var configuration = CommandConfiguration(
    commandName: "SwiftInspector",
    abstract: "A command line tool to help inspect usage of classes, protocols, properties, etc in a Swift codebase.",
    subcommands: [
      ImportsCommand.self,
      InitializerCommand.self,
      StaticUsageCommand.self,
      TypealiasCommand.self,
      TypeConformanceCommand.self,
  ])
}
