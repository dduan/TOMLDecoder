#!/bin/bash

find Sources -name '*.swift.gyb' -print0 | while IFS= read -r -d '' template; do
    base_name="$(basename "${template%.gyb}")"
    generated_name="${base_name%.swift}.Generated.swift"
    python3 Scripts/gyb.py --line-directive '' -o "$(dirname "$template")/../$generated_name" "$template"
done
