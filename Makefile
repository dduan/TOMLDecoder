SHELL               = /bin/bash
export LANG         = en_US.UTF-8
export LC_CTYPE     = en_US.UTF-8

.DEFAULT_GOAL := format

.PHONY: build test generate-code generate-tests benchmark format docs

docs:
	@Scripts/generate-docs.sh /

generate-code:
	@Scripts/generate-code.sh

generate-tests:
	@Scripts/generate-tests.py

build: generate-code
	@swift build -c release -Xswiftc -warnings-as-errors > /dev/null

test: generate-tests
	@swift test -Xswiftc -warnings-as-errors

format:
	@swiftformat .

benchmark:
	@Scripts/benchmark.sh origin/main HEAD
