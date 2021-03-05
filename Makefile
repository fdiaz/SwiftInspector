prefix ?= /usr/local
bindir ?= $(prefix)/bin
xcode_path ?= $(shell xcode-select -p)
xcode_toolchain ?= $(xcode_path)/Toolchains/XcodeDefault.xctoolchain/usr/lib/swift/macosx

.PHONY: develop
develop:
	swift package generate-xcodeproj --xcconfig-overrides settings.xcconfig
	(killall -9 Xcode && sleep 0.25) || true # Kills Xcode and waits for the process to terminate if Xcode is open.
	open SwiftInspector.xcodeproj 

.PHONY: build
build:
	swift build -c release

.PHONY: install
install: build 
	install ".build/release/swiftinspector" "$(bindir)"

.PHONY: uninstall
uninstall:
	rm -rf "$(bindir)/swiftinspector"

.PHONY: clean
clean:
	rm -rf .build

# Following https://www.smileykeith.com/2021/03/03/editing-rpaths/
.PHONY: release
release: build
	mkdir -p bin lib
	cp .build/release/swiftinspector bin
	cp "$(xcode_toolchain)/lib_InternalSwiftSyntaxParser.dylib" "lib"
	install_name_tool -delete_rpath @loader_path -delete_rpath $(xcode_toolchain) bin/swiftinspector
	install_name_tool -add_rpath @executable_path/../lib bin/swiftinspector
	zip swiftinspector.zip -r bin lib
	rm -r bin lib
