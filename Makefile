prefix ?= /usr/local
bindir ?= $(prefix)/bin

.PHONY: develop
develop:
	swift package generate-xcodeproj --xcconfig-overrides settings.xcconfig
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
