#!/bin/bash

# Scripts/test-generate.sh
#
# This script runs the code and test generation scripts and verifies that
# they don't produce any changes to the repository. This ensures that
# generated files are always up-to-date with their templates.
#
# Usage:
#   ./Scripts/test-generate.sh
#
# Exit codes:
#   0 - Success: All generated files are up-to-date
#   1 - Error: Generation scripts produced changes

set -e
set -o pipefail

# Get the script directory (same directory as this script)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Change to repository root
cd "$REPO_ROOT"

# Capture initial git status
INITIAL_STATUS=$(git status --porcelain)

echo "Running code generation..."
"$SCRIPT_DIR/generate-code.sh"

echo "Running test generation..."
python3 "$SCRIPT_DIR/generate-tests.py"

# Capture final git status
FINAL_STATUS=$(git status --porcelain)

# Check if any changes were made
if [ "$INITIAL_STATUS" != "$FINAL_STATUS" ]; then
    echo "The following files were modified:"
    git status --porcelain
    exit 1
fi

exit 0
