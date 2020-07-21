prefix ?= /usr/local
bindir ?= $(prefix)/bin

.PHONY: develop
develop:
	swift package generate-xcodeproj
	open SwiftInspector.xcodeproj 

.PHONY: build
build:
	swift build -c release

.PHONY: install
install: build
	mv ".build/release/SwiftInspector" ".build/release/swift-inspector" 
	install ".build/release/swift-inspector" "$(bindir)"

.PHONY: uninstall
uninstall:
	rm -rf "$(bindir)/swift-inspector"

.PHONY: clean
clean:
	rm -rf .build
