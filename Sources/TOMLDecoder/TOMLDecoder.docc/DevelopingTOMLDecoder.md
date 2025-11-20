# Developing TOMLDecoder

Notes for TOMLDecoder mainateners.

## Writing code

Use [swiftformat](https://github.com/nicklockwood/SwiftFormat/tree/main),
ideally, the version specified in `Scripts/format.sh` to format all code.
Patches containing unformatted code should not be accepted.
We recommend adding `swiftformat --lint .` in git pre-commit hooks.


## Writing documentation

All APIs should be documented.
Docmuntation should use Semantic Line Breaks.
This applies to docstrings, code comments, and articles.
In short, at most one sentence per line.
Read https://sembr.org/ for more info.


## Testing

Write tests with Swift's Testing framework.

Our unit tests includes the [official suite](https://github.com/toml-lang/toml-test)
from the TOML GitHub organization,
systematically translated into Swift tests.

Run tests with `swift test`, as well as `bazel test //...`.

Tests must pass on macOS, Ubuntu, and Windows for any changes to land.


## Generating code, and tests

* Parts of code is written using `gyb`. 
  Use the script `Scripts/generate-code.sh` to generate the code.
  The generated code is checked into the repo.
  Look for header comments indicating generated code,
  and only make changes in the corresponding `.gyb` files during development.
* A subset of tests are generated
  by directly copying fixtures for the official test suite.
  This is done by a script `Scripts/generate-tests.py`.
  The generated tests and fixtures are checked into the repo.
  The script contains a SHA of the test suite repo
  from which the tests are copied.
  Update the SHA to get potential newer tests.
* The script `Scripts/test-generate.sh` should be run
  to verify that the generated code and tests are up to date.
  It exists with a non-zero exit code if new code is generated.
* Generated source files should have `.Generated.swift` suffix in the filename.


## Benchmarking

Use `Scirpts/benchmark.sh baseline-SHA new-SHA`
to compare performance between two commits.

## Releasing

* Pick a new version number accoring to [Semantic Versioning](https://semver.org/).
* Places referencing the latest version needs to be updated:
    - Instructions for adding TOMLDocoder as a SwiftPM dependency
      in Getting Started.
    - MODULE.bazel
    - Potentially other places. 
      Search for the old version number in the repo.
* In CHANGLOG.md, create section for the new release.
  Move any content under `Development` to the new section.
  Note any changes that isn't in the existing notes.
* Check in the above changes and land the commit to the `main` branch.
* Tag the commit on `main` created from the previous step.
  The tag should be the literal version number (No `v` prefix).
  Push the tag to GitHub.
* Create a draft release referencing the tag on GitHub.
* Download all source archives inluded in the release in a empty directory.
  Run `shasum -a 256 *`.
  Include the output as a code block in the release notes.
* Publish the release on GitHub.

