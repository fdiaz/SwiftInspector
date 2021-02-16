prefix ?= /usr/local
bindir ?= $(prefix)/bin

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
