# Contributing to SwiftInspector

:+1: Thanks for taking the time to contribute to Swift Inspector! :+1:

This document explains some of the guidelines around contributing to this project as well as how this project is structured, so you can jump in!

## Alignment first

We ask you that if you have an idea for a new feature you [open an issue](../../issues/new).

## Submitting your changes

Whenever your feature is ready for review, please [open a PR](../../pull/new/master) with a clear list of what you've done.

For any change you make, we ask you to also **add corresponding unit tests**.

## How to contribute

### Structure of SwiftInspector

SwiftInspector is divided into three main parts:

#### SwiftInspector

Contains the main executable for this command line tool. It only contains the entry point `main.swift` file.

#### SwiftInspectorCommand

Contains all the files for managing commands and options for these commands. We can think of this as the *frontend* of this project.

#### SwiftInspectorAnalyzers

Comprises this project's analyzers. Any file related to analyzing Swift code should be put here. This is the layer that the Command interacts with directly.

#### SwiftInspectorVisitors

Comprises this project's syntax visitors. Any file that visits Swift syntax nodes should be put here. Analyzers should use the visitors in this module.

## Suggested workflow

### Writing a new Command

To add a new command create a `YourCommand.swift` file inside `SwiftInspectorCommand`  and add it to the `InspectorCommand` subcommands. Your command should delegate to `SwiftInspectorAnalyzer` for all the logic related to analyzing Swift code.

When you're ready to write a new command, I suggest you start by writing unit tests by relying on the [TestTask.swift](https://github.com/fdiaz/SwiftInspector/blob/407f34bb93df750d95cedaa10f656f0586d0769e/Sources/SwiftInspectorCommands/Tests/TestTask.swift) file to create fake commands with arguments:

```swift
private struct YourNewCommand {
  fileprivate static func run(path: String, arguments: [String] = []) throws -> TaskStatus {
    let arguments = ["newcommand", "--path", path] + arguments
    return try TestTask.run(withArguments: arguments)
  }
}
```

Refer to the [tests in the Commands target](https://github.com/fdiaz/SwiftInspector/tree/407f34bb93df750d95cedaa10f656f0586d0769e/Sources/SwiftInspectorCommands/Tests) for examples.

### Writing new Analyzer functionality

Since we want to separate the commands from the analyzer functionality, you should abstract your analyzer functionality in a class that lives in `SwiftInspectorAnalyzer`. Analyzers are a thin bridge between commands and syntax visitors – they are responsible for kicking off syntax visitation and then packaging up and returning the information gathered from syntax visitors.

### Writing new Visitor functionality

Code that visits Swift syntax nodes should be live in the `SwiftInspectorVisitors` module.

I suggest relying on the [Swift AST Explorer](https://swift-ast-explorer.com/) to understand the AST better and play around with different use cases.

When you're ready to write some code, I suggest you to start by writing unit tests by relying on the [Temporary.swift](https://github.com/fdiaz/SwiftInspector/blob/be2efb40fb1d085e69ae92a873c64fab9b66fa9a/Sources/SwiftInspectorTestHelpers/Temporary.swift) file to create fake files for testing.

```swift
context("when something happens") {
  beforeEach {
    fileURL = try! Temporary.makeFile(
      content: """
               typealias SomeTypealias = TypeA & TypeB
               """
    )
  }

  it("something happens") {
    let result = try? sut.analyze(fileURL: fileURL)
    expect(result) == Something
  }
}
```

Refer to the [tests in the Analyzer target](https://github.com/fdiaz/SwiftInspector/tree/407f34bb93df750d95cedaa10f656f0586d0769e/Sources/SwiftInspectorAnalyzers/Tests) for examples.

### Things to consider:
- We use Quick and Nimble in this repo, we rely on the following convention:
  - Use `describe` blocks for each internal and public method
  - Use `context` to setup different scenarios (e.g. "when A happens")
  - Only use one assert per test whenever possible
