#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -ne 3 ]; then
  echo "Usage: $0 <PLATFORM> <OS_VERSION> <DESTINATION>" >&2
  exit 1
fi

PLATFORM="$1"      # e.g. iOS, tvOS, watchOS, visionOS
OS_VERSION="$2"    # e.g. 26.1
DESTINATION="$3"   # e.g. platform=iOS Simulator,name=iPhone 16 Pro,OS=18.5

echo "Platform:   $PLATFORM"
echo "OS version: $OS_VERSION"
echo "Destination: $DESTINATION"

# Extract device name from DESTINATION between name= and ,OS=
device_part="${DESTINATION#*name=}"
DEVICE_NAME="${device_part%%,OS=*}"
downloaded=false

if [ -z "$DEVICE_NAME" ]; then
  echo "::error::Could not parse device name from DESTINATION: $DESTINATION" >&2
  exit 1
fi

echo "Device name: $DEVICE_NAME"

xcrun simctl list runtimes
# Find runtime identifier for this platform + OS version.
# Example line:
#   iOS 18.5 (18.5 - 22F77) - com.apple.CoreSimulator.SimRuntime.iOS-18-5
# We just grab the last field, which is the runtime ID.
RUNTIME_ID="$(
  xcrun simctl list runtimes | \
  awk -v platform="$PLATFORM" -v ver="$OS_VERSION" '
    $1 == platform && $2 == ver {
      print $NF;
      exit;
    }
  ' || true
)"

if [ -z "${RUNTIME_ID:-}" ]; then
  echo "Runtime for $PLATFORM $OS_VERSION not found. Attempting to download platform $PLATFORM..."
  downloaded=true
  xcodebuild -downloadPlatform "$PLATFORM" -buildVersion "$OS_VERSION" || true

  RUNTIME_ID="$(
    xcrun simctl list runtimes | \
    awk -v platform="$PLATFORM" -v ver="$OS_VERSION" '
      $1 == platform && $2 == ver {
        print $NF;
        exit;
      }
    ' || true
  )"
fi

if [ -z "${RUNTIME_ID:-}" ]; then
  echo "::error::No runtime for $PLATFORM $OS_VERSION found even after xcodebuild -downloadPlatform." >&2
  echo "Available runtimes:"
  xcrun simctl list runtimes || true
  exit 1
fi

echo "Using runtime id: $RUNTIME_ID"

echo "=== Devices for $PLATFORM $OS_VERSION before ensuring ==="
xcrun simctl list devices "$PLATFORM $OS_VERSION" || true

# Check if a device with this name already exists for that runtime
if ! xcrun simctl list devices "$PLATFORM $OS_VERSION" | grep -Fq "$DEVICE_NAME ("; then
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

if [ -n "${GITHUB_OUTPUT:-}" ]; then
  echo "downloaded=$downloaded" >> "$GITHUB_OUTPUT"
fi
