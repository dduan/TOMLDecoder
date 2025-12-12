#!/bin/bash

set -euo pipefail

curl -O https://download.swift.org/swiftly/linux/swiftly-$(uname -m).tar.gz
tar zxf swiftly-$(uname -m).tar.gz
./swiftly init --quiet-shell-followup
. "${SWIFTLY_HOME_DIR:-$HOME/.local/share/swiftly}/env.sh"
hash -r
swiftly install 6.2.2
swiftly use 6.2.2
swift sdk install https://download.swift.org/swift-6.2.2-release/wasm-sdk/swift-6.2.2-RELEASE/swift-6.2.2-RELEASE_wasm.artifactbundle.tar.gz --checksum 128fa003e0cad624897c2b1d5f07cedf400e3c8bd851d304e57440b591cbe606

