build:
	@swift build -c release -Xswiftc -warnings-as-errors > /dev/null

test:
	@swift test -Xswiftc -warnings-as-errors --enable-test-discovery

test-docker:
	@Scripts/ubuntu.sh TOMLDecoder test 5.3.2 bionic

