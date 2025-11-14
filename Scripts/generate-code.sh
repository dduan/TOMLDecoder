#!/bin/bash

find Sources -name '*.swift.gyb' -print0 | while IFS= read -r -d '' template; do
    python3 Scripts/gyb.py --line-directive '' -o "$(dirname "$template")/../$(basename "${template%.gyb}")" "$template"
done
