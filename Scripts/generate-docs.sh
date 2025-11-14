#!/bin/bash

swift build --target TOMLDecoder \
  -Xswiftc -emit-symbol-graph \
  -Xswiftc -emit-symbol-graph-dir \
  -Xswiftc .build/symbol-graphs

xcrun docc convert Sources/TOMLDecoder/TOMLDecoder.docc \
  --fallback-display-name TOMLDecoder \
  --fallback-bundle-identifier ca.duan.TOMLDecoder \
  --fallback-bundle-version 1.0 \
  --additional-symbol-graph-dir .build/symbol-graphs \
  --transform-for-static-hosting \
  --hosting-base-path / \
  --output-path Docs
