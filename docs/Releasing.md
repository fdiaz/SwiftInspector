# Releasing a new version of SwiftInspector

1. Run `make release` from the root of the repo. This will generate a `swiftinspector.zip` file.
1. Create a new [draft release](https://github.com/fdiaz/SwiftInspector/releases/new) following [semantic versioning](https://semver.org/) for both the tag version and the release title.
1. In the description of the release point out all the PRs that have been merged since the previous version and describe the new features. 
1. Attach `swiftinspector.zip` to the release
1. Select the `This is a pre-release` checkbox
1. Click on `Publish release`
