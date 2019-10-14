# Contributing to SwiftInspector

:+1: Thanks for taking the time to contribute to Swift Inspector! :+1:

This document explains some of the guidelines around contributing to this project as well as how this project is structured, so you can jump in!

## Alignment first

We ask you that if you have an idea for a new feature you [open an issue](https://git.musta.ch/francisco-diaz/SwiftInspector/issues/new) to discuss or reach out to [francisco-diaz](https://git.musta.ch/francisco-diaz) to align first.

## Submitting your changes

Whenever your feature is ready for review, please [open a PR](https://git.musta.ch/francisco-diaz/SwiftInspector/pull/new/master) with a clear list of what you've done.

For any change you make, we ask you to also **add corresponding unit tests**.

## How to contribute

### Structure of SwiftInspector

SwiftInspector is divided into two main parts:

#### SwiftInspector

Contains the main executable for this command line tool. It contains the entry point `main.swift` file.


#### SwiftInspectorKit

It’s divided into **Frontend** and **Core**.

- **Frontend**: The scaffolding around managing commands and options for these commands. This is what the end user interacts with.
- **Core**: In here is where the magic happens. Any file that's related to analyzing Swift code should go in here.


### Adding a new Command

To add a new command create a `YourCommand.swift` file inside the `Frontent/Commands` folder in `SwiftInspectorKiit`. Your command should delegate to files under `Core/` for all the logic related to analyzing Swift code.
