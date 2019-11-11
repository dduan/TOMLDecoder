#!/bin/bash

set -e

version=2.10.1
tmp=tmp
bin=$tmp/xcodegen

if [[ -f $bin ]] && [[ "$($bin --version)" =~ "$version" ]]; then
    exit 0
fi

zip=$tmp/xcodegen.zip
mkdir -p $tmp
curl -L https://github.com/yonaskolb/XcodeGen/releases/download/$version/xcodegen.zip -o $zip
unzip -o $zip -d /tmp
mv /tmp/xcodegen/bin/xcodegen $bin
