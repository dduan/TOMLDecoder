#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -ne 3 ]; then
  echo "Usage: $0 <PLATFORM> <OS_VERSION> <DESTINATION>" >&2
  exit 1
fi

PLATFORM="$1"      # e.g. iOS, tvOS, watchOS, visionOS
OS_VERSION="$2"    # e.g. 26.1
DESTINATION="$3"   # e.g. platform=iOS Simulator,name=iPhone 16 Pro,OS=18.5
EXPORT_BASE="${SIMRUNTIME_EXPORT_BASE:-${RUNNER_TEMP:-/tmp}/simruntimes}"
EXPORT_DIR="${EXPORT_BASE}/${PLATFORM}/${OS_VERSION}"

echo "Platform:   $PLATFORM"
echo "OS version: $OS_VERSION"
echo "Destination: $DESTINATION"
echo "Runtime export dir: $EXPORT_DIR"

# Extract device name from DESTINATION between name= and ,OS=
device_part="${DESTINATION#*name=}"
DEVICE_NAME="${device_part%%,OS=*}"

if [ -z "$DEVICE_NAME" ]; then
  echo "::error::Could not parse device name from DESTINATION: $DESTINATION" >&2
  exit 1
fi

echo "Device name: $DEVICE_NAME"

device_exists_exact() {
  local platform="$1"
  local os_version="$2"
  local device_name="$3"

  xcrun simctl list devices --json | \
    jq -e --arg platform "$platform" --arg os_version "$os_version" --arg name "$device_name" '
      (.devices[$platform + " " + $os_version] // []) | map(select(.name == $name)) | length > 0
    ' >/dev/null
}

find_runtime_id() {
  xcrun simctl list runtimes | \
    awk -v platform="$PLATFORM" -v ver="$OS_VERSION" '
      $1 == platform && $2 == ver {
        print $NF;
        exit;
      }
    ' || true
}

# Find runtime identifier for this platform + OS version.
# Example line:
#   iOS 18.5 (18.5 - 22F77) - com.apple.CoreSimulator.SimRuntime.iOS-18-5
# We just grab the last field, which is the runtime ID.
RUNTIME_ID="$(find_runtime_id)"

if [ -z "${RUNTIME_ID:-}" ]; then
  DMG="$(find "$EXPORT_DIR" -maxdepth 1 -name '*.dmg' -print -quit 2>/dev/null || true)"

  if [ -n "$DMG" ]; then
    echo "Runtime for $PLATFORM $OS_VERSION not found. Importing from cached export: $DMG"
    sudo xcodebuild -importPlatform "$DMG"
    RUNTIME_ID="$(find_runtime_id)"
  fi
fi

if [ -z "${RUNTIME_ID:-}" ]; then
  echo "Runtime for $PLATFORM $OS_VERSION not found. Downloading and exporting to $EXPORT_DIR..."
  mkdir -p "$EXPORT_DIR"
  xcodebuild -downloadPlatform "$PLATFORM" -buildVersion "$OS_VERSION" -exportPath "$EXPORT_DIR" || true

  DMG="$(find "$EXPORT_DIR" -maxdepth 1 -name '*.dmg' -print -quit 2>/dev/null || true)"
  if [ -z "$DMG" ]; then
    echo "::error::xcodebuild did not produce a runtime export (.dmg) in $EXPORT_DIR" >&2
    exit 1
  fi

  echo "Importing downloaded runtime from $DMG"
  sudo xcodebuild -importPlatform "$DMG"
  RUNTIME_ID="$(find_runtime_id)"
fi

if [ -z "${RUNTIME_ID:-}" ]; then
  echo "::error::No runtime for $PLATFORM $OS_VERSION found even after attempting import/download." >&2
  echo "Available runtimes:"
  xcrun simctl list runtimes || true
  exit 1
fi

echo "Using runtime id: $RUNTIME_ID"

echo "=== Devices for $PLATFORM $OS_VERSION before ensuring ==="
xcrun simctl list devices "$PLATFORM $OS_VERSION" || true

# Check if a device with this name already exists for that runtime
if ! device_exists_exact "$PLATFORM" "$OS_VERSION" "$DEVICE_NAME"; then
  echo "No device named '$DEVICE_NAME' for $PLATFORM $OS_VERSION. Creating…"

  # Find a device type whose display name matches DEVICE_NAME
  # Example line:
  #   iPhone 16 Pro (com.apple.CoreSimulator.SimDeviceType.iPhone-16-Pro)
  DEVICE_TYPE_ID="$(
    xcrun simctl list devicetypes | \
    awk -v name="$DEVICE_NAME" -F '[()]' '
      $1 ~ name"[[:space:]]*$" {
        print $2;
        exit;
      }
    ' || true
  )"

  if [ -z "${DEVICE_TYPE_ID:-}" ]; then
    echo "::error::Could not find a device type matching '$DEVICE_NAME'." >&2
    echo "Available device types:"
    xcrun simctl list devicetypes || true
    exit 1
  fi

  echo "Using device type id: $DEVICE_TYPE_ID"
  xcrun simctl create "$DEVICE_NAME" "$DEVICE_TYPE_ID" "$RUNTIME_ID"
else
  echo "Device '$DEVICE_NAME' already exists for $PLATFORM $OS_VERSION."
fi
