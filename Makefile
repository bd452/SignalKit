IOS_SDK := $(shell xcrun --sdk iphonesimulator --show-sdk-path)
IOS_TRIPLE := arm64-apple-ios15.0-simulator
SIMULATOR_DEST := platform=iOS Simulator,name=iPhone 17,OS=26.5

.PHONY: build test test-macos

build:
	swift build --triple $(IOS_TRIPLE) --sdk $(IOS_SDK)

build-macos:
	swift build

test:
	xcodebuild -scheme SignalKit -destination '$(SIMULATOR_DEST)' test

test-macos:
	swift test
