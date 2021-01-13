SHELL               = /bin/bash
export LANG         = en_US.UTF-8
export LC_CTYPE     = en_US.UTF-8

.DEFAULT_GOAL := build

build:
	@swift build -c release -Xswiftc -warnings-as-errors > /dev/null

test-SwiftPM:
	@swift test -Xswiftc -warnings-as-errors --enable-test-discovery

test-docker:
	@Scripts/docker.sh TOMLDecoder 'swift test -Xswiftc -warnings-as-errors --enable-test-discovery' 5.3.1 focal

benchmark:
	@cd Benchmarks; swift run -c release
