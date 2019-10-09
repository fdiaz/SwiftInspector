# Contributing to SwiftInspector

:+1: Thanks for taking the time to contribute to Swift Inspector! :+1:

This document explains some of the guidelines around contributing to this project as well as how this project is structured, so you can jump start!

## Alignment first

We ask you that if you have an idea for a new feature you [open an issue](https://git.musta.ch/francisco-diaz/SwiftInspector/issues/new) to discuss or reach out to [#native-infra](https://airbnb.slack.com/app_redirect?channel=native-infra) to align first.

## Submitting your changes

Whenever your feature is ready for review, please [open a PR](https://git.musta.ch/francisco-diaz/SwiftInspector/pull/new/master) with a clear list of what you've done.

For any change you make, we ask you to also **add corresponding unit tests**.

## How to contribute

### Structure of SwiftInspector

SwiftInspector is divided into two main parts:

#### SwiftInspector

Contains the main executable for this command line tool. This contains the entry point `main.swift` file and the scaffolding around managing commands and options for these commands. We can think of this as the *"frontend"* of this project.

#### SwiftInspectorKit

Is the *"core"* or *"backend"* of this project. In here is where the magic happens. You should put any file that's related to reading o rewriting Swift code in here.

### Adding a new Command

To add a new command create a `YourCommand.swift` file inside the `Commands` folder in `SwiftInspector`. 

`YourCommand.swift` should look something like this;

```swift
final class YourCommand: CommandProtocol {
  typealias Options = NoOptions

  let verb = "your-command"
  let function = "Description of your command"

  func run(_ options: Options) -> Result<(), YourErrorType> {
    // New functionality here
    return ()
  }
}
```

### Adding new functionality

Since we want to separate the commands from the core functionality, you should abstract your core functionality in a class that lives in the `Core` folder in `SwiftInspectorKit`.
