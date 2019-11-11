build: update-linux-test-manifest
	@swift build -c release -Xswiftc -warnings-as-errors > /dev/null

test:
	@swift test -Xswiftc -warnings-as-errors

generate-xcodeproj:
	@Scripts/ensure-xcodegen.sh
	@tmp/xcodegen

update-linux-test-manifest:
ifeq ($(shell uname),Darwin)
	@rm Tests/TOMLDecoderTests/XCTestManifests.swift
	@touch Tests/TOMLDecoderTests/XCTestManifests.swift
	@swift test --generate-linuxmain
else
	@echo "Only works on macOS"
endif

test-codegen: update-linux-test-manifest generate-xcodeproj
	@git diff --exit-code

clean-dependencies:
	@rm -rf Dependencies/NetTime
	@rm -rf Dependencies/TOMLDeserializer

test-docker:
	@Scripts/ubuntu.sh TOMLDecoder test 5.1.1 bionic

clean-carthage:
	@echo "Deleting Carthage artifacts…"
	@rm -rf Carthage
	@rm -rf TOMLDecoder.framework.zip

carthage-archive: clean-carthage install-carthage
	@carthage build --archive

install-carthage:
	brew update
	brew outdated carthage || brew upgrade carthage

install-%:
	true

test-SwiftPM: test

install-CocoaPods:
	sudo gem install cocoapods -v 1.8.3

test-CocoaPods:
	pod lib lint --verbose

test-iOS:
	set -o pipefail && \
		xcodebuild \
		-project TOMLDecoder.xcodeproj \
		-scheme TOMLDecoder \
		-configuration Release \
		-destination "name=iPhone 11,OS=13.1" \
		test

test-macOS:
	set -o pipefail && \
		xcodebuild \
		-project TOMLDecoder.xcodeproj \
		-scheme TOMLDecoder \
		-configuration Release \
		test \

test-tvOS:
	set -o pipefail && \
		xcodebuild \
		-project TOMLDecoder.xcodeproj \
		-scheme TOMLDecoder \
		-configuration Release \
		-destination "platform=tvOS Simulator,name=Apple TV,OS=13.0" \
		test \

test-carthage:
	set -o pipefail && \
		carthage build \
		--no-skip-current \
		--configuration Release \
		--verbose
	ls Carthage/build/Mac/TOMLDecoder.framework
	ls Carthage/build/iOS/TOMLDecoder.framework
	ls Carthage/build/tvOS/TOMLDecoder.framework
	ls Carthage/build/watchOS/TOMLDecoder.framework

