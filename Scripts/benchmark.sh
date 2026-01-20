#!/bin/bash
set -euo pipefail

./Scripts/benchmark_run.sh "$@" >&2
./Scripts/benchmark_report.sh "$@"
