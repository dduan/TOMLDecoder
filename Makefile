SHELL               = /bin/bash
export LANG         = en_US.UTF-8
export LC_CTYPE     = en_US.UTF-8

.DEFAULT_GOAL := build

.PHONY: build test generate-code generate-tests benchmark

generate-code:
	@Scripts/generate-code.sh

generate-tests:
	@Scripts/generate-tests.py

build: generate-code
	@Scripts/generate-code.sh
	@swift build -c release -Xswiftc -warnings-as-errors > /dev/null

test: generate-tests
	@swift test -Xswiftc -warnings-as-errors

benchmark:
	@Scripts/benchmark.sh origin/main HEAD
