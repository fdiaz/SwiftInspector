![swiftinspector](img/swiftinspector.png)

![](https://github.com/fdiaz/SwiftInspector/workflows/macOS/badge.svg) 
[![codecov](https://codecov.io/gh/fdiaz/SwiftInspector/branch/main/graph/badge.svg)](https://codecov.io/gh/fdiaz/SwiftInspector)
[![Project Status: WIP – Initial development is in progress, but there has not yet been a stable, usable release suitable for the public.](https://www.repostatus.org/badges/latest/wip.svg)](https://www.repostatus.org/#wip)

`SwiftInspector` is a command line tool and set of SPM libraries built on top of [SwiftSyntax](https://github.com/apple/swift-syntax). `SwiftInspector` reliably finds usages of classes, protocols, properties, etc. in a codebase by analyzing the Swift [AST](https://en.wikipedia.org/wiki/Abstract_syntax_tree).

## Disclaimer

This project is currently under development and can have breaking API changes.

---

## Requirements

- Swift 5.6
- Xcode 13.3+

## Install

Run the following command:

```
$ git clone git@github.com:fdiaz/SwiftInspector.git
$ cd SwiftInspector
$ make install
```

## Develop

If you want to contribute to this project, please take a look at our [CONTRIBUTING](CONTRIBUTING.md) guidelines. To open the project in Xcode, open the `Package.swift` file at the root of the repo.

## Default branch
The default branch of this repository is `main`. Between the initial commit and [75bd9f4
](https://github.com/fdiaz/SwiftInspector/commit/75bd9f440d72ade9abd1e1d8e9d118e8bb8701a0), the default branch of this repository was `master`. See [#38](https://github.com/fdiaz/SwiftInspector/issues/38) for more details on why this change was made.

## License

[MIT](LICENSE)

![Powered by MacStadium](img/macstadium.png)
