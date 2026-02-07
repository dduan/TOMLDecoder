SHELL               = /bin/bash
export LANG         = en_US.UTF-8
export LC_CTYPE     = en_US.UTF-8
EMBED_SWIFT         ?= $(shell \
	if command -v swiftly >/dev/null 2>&1; then \
		toolchain="$$(swiftly use --print-location 2>/dev/null | head -n1)"; \
		if [ -x "$$toolchain/usr/bin/swift" ]; then \
			echo "$$toolchain/usr/bin/swift"; \
		else \
			command -v swift; \
		fi; \
	else \
		command -v swift; \
	fi \
)

.DEFAULT_GOAL := format

.PHONY: build test embedded generate-code generate-tests benchmark format docs

docs:
	@Scripts/generate-docs.sh /

generate-code:
	@Scripts/generate-code.sh

generate-tests:
	@Scripts/generate-tests.py

build: generate-code
	@swift build -c release -Xswiftc -warnings-as-errors > /dev/null

embedded: generate-code
	@$(EMBED_SWIFT) build -c release --target TOMLDecoder --disable-default-traits -Xswiftc -target -Xswiftc arm64-apple-macos14.0 -Xswiftc -enable-experimental-feature -Xswiftc Embedded -Xswiftc -wmo

test: generate-tests
	@swift test -Xswiftc -warnings-as-errors

format:
	@swiftformat .

benchmark:
	@Scripts/benchmark.sh origin/main HEAD
