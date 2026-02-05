#!/usr/bin/env python3
"""Synchronise local fixtures with the official toml-test suite."""

from __future__ import annotations

import argparse
import os
import shutil
import sys
import urllib.request
import zipfile
from collections import defaultdict
import re
from pathlib import Path
import textwrap
from typing import Iterable, List


REPO_ROOT = Path(__file__).resolve().parent.parent
DEFAULT_SPEC_VERSION = "1.1.0"
TMP_ROOT = REPO_ROOT / "tmp"
TOML_TEST_REPO_URL = "git@github.com:toml-lang/toml-test.git"
TOML_TEST_COMMIT = "0ee318ae97ae5dec5f74aeccafbdc75f435580e2"
TOML_TEST_DIR = TMP_ROOT / "toml-test"
VALID_FIXTURES_DIR = REPO_ROOT / "Tests" / "TOMLDecoderTests" / "valid_fixtures"
INVALID_FIXTURES_DIR = REPO_ROOT / "Tests" / "TOMLDecoderTests" / "invalid_fixtures"
VALID_TEST_FILE = REPO_ROOT / "Tests" / "TOMLDecoderTests" / "ValidationTests.Generated.swift"
INVALID_TEST_FILE = REPO_ROOT / "Tests" / "TOMLDecoderTests" / "InvalidationTests.Generated.swift"
TAGS_FILE = REPO_ROOT / "Tests" / "TOMLDecoderTests" / "Support" / "Tags.Generated.swift"


def _read_lines(path: Path) -> List[str]:
    return [line.strip() for line in path.read_text(encoding="utf-8").splitlines() if line.strip()]


def _swift_string_literal(value: str) -> str:
    escaped = value.replace("\\", "\\\\").replace('"', '\\"')
    return f'"{escaped}"'


def _swift_fixture_expression(relative_path: str) -> str:
    components = relative_path.split("/")
    items = ", ".join(_swift_string_literal(component) for component in components)
    return f"[{items}]"


def _ensure_toml_test_checkout() -> Path:
    TMP_ROOT.mkdir(parents=True, exist_ok=True)

    if not TOML_TEST_DIR.exists():
        archive_url = f"https://github.com/toml-lang/toml-test/archive/{TOML_TEST_COMMIT}.zip"
        archive_path = TMP_ROOT / f"toml-test-{TOML_TEST_COMMIT}.zip"

        print(f"Downloading toml-test archive from {archive_url}")
        urllib.request.urlretrieve(archive_url, archive_path)

        print(f"Extracting archive to {TOML_TEST_DIR}")
        with zipfile.ZipFile(archive_path, 'r') as zip_ref:
            zip_ref.extractall(TMP_ROOT)

        # The extracted folder will be named toml-test-{commit}
        extracted_dir = TMP_ROOT / f"toml-test-{TOML_TEST_COMMIT}"
        extracted_dir.rename(TOML_TEST_DIR)

        # Clean up the archive
        archive_path.unlink()

    return TOML_TEST_DIR


def _sanitize_test_name(relative_path: str, counters: defaultdict[str, int]) -> str:
    components = relative_path.split("/")

    if len(components) == 1:
        # Single component - just clean it up
        normalized = components[0].replace("_", " ").replace("-", " ").replace(".", " ")
        normalized = " ".join(normalized.split()) or "fixture"
    else:
        # Multiple components - include first component in brackets
        first_component = components[0]
        rest = []
        for component in components[1:]:
            cleaned = component.replace("_", " ").replace("-", " ").replace(".", " ")
            rest.append(cleaned)
        rest_normalized = " ".join(rest)
        rest_normalized = " ".join(rest_normalized.split()) or "fixture"
        normalized = f"[{first_component}] {rest_normalized}"

    counters[normalized] += 1
    if counters[normalized] == 1:
        return normalized
    return f"{normalized} {counters[normalized]}"


def _make_swift_identifier_from_path(relative_path: str, counters: defaultdict[str, int]) -> str:
    """Convert a fixture path into a Swift-safe identifier.

    Format: <primary>__<rest>, where primary is the first path component and rest is the remainder.
    Non-alphanumerics become underscores; leading digits are prefixed with 'test_'.
    """
    components = relative_path.split("/")
    primary = components[0] if components else "test"
    rest_components = components[1:]

    def slug(value: str) -> str:
        return re.sub(r"[^A-Za-z0-9]+", "_", value).strip("_")

    primary_slug = slug(primary) or "test"
    rest_slug = slug(" ".join(rest_components)) if rest_components else ""

    base = f"{primary_slug}__{rest_slug}" if rest_slug else primary_slug
    if base and base[0].isdigit():
        base = f"test_{base}"
    elif not base:
        base = "test"

    counters[base] += 1
    if counters[base] > 1:
        base = f"{base}_{counters[base]}"
    return base


def _get_test_tag(relative_path: str) -> str:
    """Extract the first path component as a tag name."""
    components = relative_path.split("/")
    if len(components) > 1:
        # Convert hyphens and dots to underscores for valid Swift identifier
        tag = components[0].replace("-", "_").replace(".", "_")
        return f".{tag}"
    return ""


def _generate_tag_declarations(tags: set[str]) -> str:
    """Generate tag extension declarations."""
    tag_declarations = []
    for tag in sorted(tags):
        tag_name = tag[1:]  # Remove the leading dot
        tag_declarations.append(f"    @Tag static var {tag_name}: Self")
    return "extension Tag {\n" + "\n".join(tag_declarations) + "\n}"


def _generate_tags_file(tags: set[str], commit: str, spec_version: str) -> str:
    """Generate the shared tags file."""
    tag_declarations = _generate_tag_declarations(tags)

    template = textwrap.dedent(
        """// Generated by Scripts/generate-tests.py
// Source: toml-test commit __COMMIT__ (spec __SPEC_VERSION__)

import Testing

__TAG_DECLARATIONS__
"""
    )

    return (
        template
        .replace("__COMMIT__", commit)
        .replace("__SPEC_VERSION__", spec_version)
        .replace("__TAG_DECLARATIONS__", tag_declarations)
    )


def _copy_valid_fixture(base_path: Path, source_root: Path) -> None:
    destination_dir = VALID_FIXTURES_DIR / base_path.parent
    destination_dir.mkdir(parents=True, exist_ok=True)

    for extension in (".toml", ".json"):
        source = source_root / "tests" / "valid" / base_path.with_suffix(extension)
        if not source.exists():
            raise FileNotFoundError(f"Missing valid fixture companion: {source}")
        target = destination_dir / base_path.with_suffix(extension).name
        shutil.copyfile(source, target)


def _copy_invalid_fixture(base_path: Path, source_root: Path) -> None:
    destination_dir = INVALID_FIXTURES_DIR / base_path.parent
    destination_dir.mkdir(parents=True, exist_ok=True)

    source = source_root / "tests" / "invalid" / base_path.with_suffix(".toml")
    if not source.exists():
        raise FileNotFoundError(f"Missing invalid fixture: {source}")
    target = destination_dir / base_path.with_suffix(".toml").name
    shutil.copyfile(source, target)


def _generate_valid_test_file(fixtures: Iterable[str], commit: str, spec_version: str) -> str:
    display_counters: defaultdict[str, int] = defaultdict(int)
    identifier_counters: defaultdict[str, int] = defaultdict(int)
    tests: List[str] = []

    for relative in fixtures:
        display_name = _sanitize_test_name(relative, display_counters)
        method_name = _make_swift_identifier_from_path(relative, identifier_counters)
        fixture_expr = _swift_fixture_expression(relative)
        tag = _get_test_tag(relative)

        if tag:
            test_decorator = f"@Test(\"{display_name}\", .tags({tag}))\n    "
        else:
            test_decorator = f"@Test(\"{display_name}\")\n    "

        tests.append(
            "    {decorator}func {name}() throws {{\n"
            "        try verifyByFixture(pathComponents: {fixture})\n"
            "    }}\n".format(decorator=test_decorator, name=method_name, fixture=fixture_expr)
        )

    tests_block = "\n".join(tests).rstrip()

    template = textwrap.dedent(
        """// Generated by Scripts/generate-tests.py
// Source: toml-test commit __COMMIT__ (spec __SPEC_VERSION__)

import Foundation
import Testing
import TOMLDecoder

@Suite
struct TOMLValidationTests {
    private var directoryURL: URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .appendingPathComponent("valid_fixtures")
    }

    private func verifyByFixture(pathComponents: [String], sourceLocation: SourceLocation = #_sourceLocation) throws {
        let baseURL = pathComponents.reduce(directoryURL) { $0.appendingPathComponent($1) }
        let jsonURL = baseURL.appendingPathExtension("json")
        let tomlURL = baseURL.appendingPathExtension("toml")
        try TOMLComplianceSupport.verifyValidFixture(jsonURL: jsonURL, tomlURL: tomlURL, sourceLocation: sourceLocation)
    }

__TESTS__
}
"""
    )

    return (
        template
        .replace("__COMMIT__", commit)
        .replace("__SPEC_VERSION__", spec_version)
        .replace("__TESTS__", tests_block)
    )

def _generate_invalid_test_file(fixtures: Iterable[str], commit: str, spec_version: str) -> str:
    display_counters: defaultdict[str, int] = defaultdict(int)
    identifier_counters: defaultdict[str, int] = defaultdict(int)
    tests: List[str] = []

    for relative in fixtures:
        display_name = _sanitize_test_name(relative, display_counters)
        method_name = _make_swift_identifier_from_path(relative, identifier_counters)
        fixture_expr = _swift_fixture_expression(relative)
        tag = _get_test_tag(relative)

        if tag:
            test_decorator = f"@Test(\"{display_name}\", .tags({tag}))\n    "
        else:
            test_decorator = f"@Test(\"{display_name}\")\n    "

        tests.append(
            "    {decorator}func {name}() throws {{\n"
            "        try invalidate(pathComponents: {fixture})\n"
            "    }}\n".format(decorator=test_decorator, name=method_name, fixture=fixture_expr)
        )

    tests_block = "\n".join(tests).rstrip()

    template = textwrap.dedent(
        """// Generated by Scripts/generate-tests.py
// Source: toml-test commit __COMMIT__ (spec __SPEC_VERSION__)

import Foundation
import Testing
import TOMLDecoder

@Suite
struct TOMLInvalidationTests {
    private var directoryURL: URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .appendingPathComponent("invalid_fixtures")
    }

    private func invalidate(pathComponents: [String], sourceLocation: SourceLocation = #_sourceLocation) throws {
        let baseURL = pathComponents.reduce(directoryURL) { $0.appendingPathComponent($1) }
        let tomlURL = baseURL.appendingPathExtension("toml")
        try TOMLComplianceSupport.verifyInvalidFixture(tomlURL: tomlURL, sourceLocation: sourceLocation)
    }

__TESTS__
}
"""
    )

    return (
        template
        .replace("__COMMIT__", commit)
        .replace("__SPEC_VERSION__", spec_version)
        .replace("__TESTS__", tests_block)
    )

def main(argv: List[str]) -> int:
    parser = argparse.ArgumentParser(description="Synchronise fixtures from toml-test")
    parser.add_argument(
        "--spec-version",
        default=DEFAULT_SPEC_VERSION,
        help="TOML specification version to use",
    )
    parser.add_argument(
        "--use-existing-fixtures",
        action="store_true",
        help="Reuse existing fixtures under Tests/TOMLDecoderTests instead of downloading toml-test",
    )
    args = parser.parse_args(argv)

    if args.use_existing_fixtures:
        commit = "local-fixtures"
        valid_fixtures = [
            str(path.relative_to(VALID_FIXTURES_DIR).with_suffix(""))
            .replace(os.sep, "/")
            for path in sorted(VALID_FIXTURES_DIR.rglob("*.toml"))
        ]
        invalid_fixtures = [
            str(path.relative_to(INVALID_FIXTURES_DIR).with_suffix(""))
            .replace(os.sep, "/")
            for path in sorted(INVALID_FIXTURES_DIR.rglob("*.toml"))
        ]
    else:
        toml_test_dir = _ensure_toml_test_checkout()

        list_file = toml_test_dir / "tests" / f"files-toml-{args.spec_version}"
        if not list_file.exists():
            raise SystemExit(f"spec version {args.spec_version} is not available (missing {list_file})")

        # Use the known commit hash since we downloaded the archive for this specific commit
        commit = TOML_TEST_COMMIT

        lines = _read_lines(list_file)

        if VALID_FIXTURES_DIR.exists():
            shutil.rmtree(VALID_FIXTURES_DIR)
        if INVALID_FIXTURES_DIR.exists():
            shutil.rmtree(INVALID_FIXTURES_DIR)

        VALID_FIXTURES_DIR.mkdir(parents=True)
        INVALID_FIXTURES_DIR.mkdir(parents=True)

        valid_fixtures = []
        invalid_fixtures = []
        seen_valid: set[str] = set()
        seen_invalid: set[str] = set()

        for line in lines:
            path = Path(line)
            if path.suffix != ".toml":
                continue

            if path.parts[0] == "valid":
                base = Path(*path.parts[1:]).with_suffix("")
                _copy_valid_fixture(base, toml_test_dir)
                key = str(base).replace(os.sep, "/")
                if key not in seen_valid:
                    valid_fixtures.append(key)
                    seen_valid.add(key)
            elif path.parts[0] == "invalid":
                base = Path(*path.parts[1:]).with_suffix("")
                _copy_invalid_fixture(base, toml_test_dir)
                key = str(base).replace(os.sep, "/")
                if key not in seen_invalid:
                    invalid_fixtures.append(key)
                    seen_invalid.add(key)

        valid_fixtures.sort()
        invalid_fixtures.sort()

    # Collect all tags from both valid and invalid fixtures
    all_tags: set[str] = set()
    for fixture in valid_fixtures + invalid_fixtures:
        tag = _get_test_tag(fixture)
        if tag:
            all_tags.add(tag)

    # Write the shared tags file
    TAGS_FILE.write_text(
        _generate_tags_file(all_tags, commit, args.spec_version),
        encoding="utf-8",
    )

    VALID_TEST_FILE.write_text(
        _generate_valid_test_file(valid_fixtures, commit, args.spec_version),
        encoding="utf-8",
    )
    INVALID_TEST_FILE.write_text(
        _generate_invalid_test_file(invalid_fixtures, commit, args.spec_version),
        encoding="utf-8",
    )

    print(
        f"Copied {len(valid_fixtures)} valid fixtures and {len(invalid_fixtures)} invalid fixtures "
        f"from toml-test commit {commit} (spec {args.spec_version})"
    )
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
