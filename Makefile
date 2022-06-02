prefix ?= /usr/local
bindir ?= $(prefix)/bin
xcode_path ?= $(shell xcode-select -p)
xcode_toolchain ?= $(xcode_path)/Toolchains/XcodeDefault.xctoolchain/usr/lib/swift/macosx

.PHONY: build
build:
	swift build -c release --arch arm64 --arch x86_64

.PHONY: install
install: build 
	install ".build/release/swiftinspector" "$(bindir)"

.PHONY: uninstall
uninstall:
	rm -rf "$(bindir)/swiftinspector"

.PHONY: clean
clean:
	rm -rf .build

.PHONY: release
release: build
	cp .build/apple/Products/Release/swiftinspector .
	zip "swiftinspector-$(shell git rev-parse --short HEAD).zip" swiftinspector
	rm swiftinspector
