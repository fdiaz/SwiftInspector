# SwiftInspector

![](https://github.com/fdiaz/SwiftInspector/workflows/macOS/badge.svg) 
[![codecov](https://codecov.io/gh/fdiaz/SwiftInspector/branch/master/graph/badge.svg)](https://codecov.io/gh/fdiaz/SwiftInspector)
[![Project Status: WIP – Initial development is in progress, but there has not yet been a stable, usable release suitable for the public.](https://www.repostatus.org/badges/latest/wip.svg)](https://www.repostatus.org/#wip)

`SwiftInspector` is a command line tool built on top of [SwiftSyntax](https://github.com/apple/swift-syntax) to help inspect usage of classes, protocols, properties, etc in a Swift codebase.

## Disclaimer

This project is currently under development and can have breaking API changes.

---

## Generating an Xcode Project

To see this project locally in Xcode you can run the following command on the root of this project:
`swift package generate-xcodeproj`

This will generate an `SwiftInspector.xcodeproj` in the root of this repository.

## Run this project

Open the generated Xcode project:

`open SwiftInspector.xcodeproj`

Then run the project using ⌘ R. 

Make sure to select "My Mac" as the device.
