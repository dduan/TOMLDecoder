#!/bin/bash
set -euo pipefail

export TOMLDECODER_BENCHMARKS=1

baseline=$(git rev-parse "$1")
target=$(git rev-parse "$2")

if [ -d ".benchmarkBaselines/TOMLDecoderBenchmarks/$baseline" ]; then
    echo "Reusing baseline for $baseline"
else
    git checkout "$baseline"
    swift package -c release --allow-writing-to-package-directory \
        benchmark baseline update "$baseline" --grouping metric
fi

git checkout "$target"
swift package -c release benchmark baseline compare "$baseline"
