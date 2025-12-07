#!/bin/bash

# Each release, as well as the `main` branch,
# has its own instance of the doc site.

set -euo pipefail

if [ "$#" -lt 1 ]; then
    branch="main"
else
    branch="$1"
fi

if [ -z "${GITHUB_SHA:-}" ]; then
    GITHUB_SHA=$(git rev-parse HEAD)
fi

git config user.email "$(git show -s --format='%ae' HEAD)"
git config user.name "$(git show -s --format='%an' HEAD)"
rm -rf /tmp/public
cp -r Docs /tmp/public
git fetch origin gh-pages:refs/remotes/origin/gh-pages --depth=1
git checkout gh-pages
rm -rf "./${branch}"
rm -rf .build
cp -r /tmp/public "./${branch}"
git add .
git commit -m "Deploy $GITHUB_SHA" || true
git push origin gh-pages || true
