#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -ne 3 ]; then
  echo "Usage: $0 <PLATFORM> <OS_VERSION> <DESTINATION>" >&2
  exit 1
fi

PLATFORM="$1"      # e.g. iOS, tvOS, watchOS, visionOS
OS_VERSION="$2"    # e.g. 26.1
DESTINATION="$3"   # e.g. platform=tvOS Simulator,name=Apple TV,OS=26.1

echo "Platform:   $PLATFORM"
echo "OS version: $OS_VERSION"
echo "Destination: $DESTINATION"

# Extract device name from DESTINATION between name= and ,OS=
# Example: "platform=tvOS Simulator,name=Apple TV,OS=26.1"
# -> DEVICE_NAME="Apple TV"
device_part="${DESTINATION#*name=}"
DEVICE_NAME="${device_part%%,OS=*}"

if [ -z "$DEVICE_NAME" ]; then
  echo "::error::Could not parse device name from DESTINATION: $DESTINATION" >&2
  exit 1
fi

echo "Device name: $DEVICE_NAME"
echo "=== Runtimes before ensuring ==="
xcrun simctl list runtimes || true

# Find runtime identifier for this platform + OS version
# Lines look like:
#   tvOS 26.1 (26.1 - 123A456) (com.apple.CoreSimulator.SimRuntime.tvOS-26-1) ...
RUNTIME_ID="$(
  xcrun simctl list runtimes | \
  awk -v platform="$PLATFORM" -v ver="$OS_VERSION" '
    $0 ~ platform" "ver {
      match($0, /\(([^()]*)\)/, m);
      if (m[1] ~ /^com\.apple\.CoreSimulator\.SimRuntime\./) {
        print m[1];
        exit
      }
    }
  ' || true
)"

if [ -z "${RUNTIME_ID:-}" ]; then
  echo "Runtime for $PLATFORM $OS_VERSION not found. Attempting to download platform $PLATFORM..."
  # This downloads the latest available runtime(s) for the platform.
  # It might not match OS_VERSION exactly, but often fixes missing runtimes.
  xcodebuild -downloadPlatform "$PLATFORM" || true

  RUNTIME_ID="$(
    xcrun simctl list runtimes | \
    awk -v platform="$PLATFORM" -v ver="$OS_VERSION" '
      $0 ~ platform" "ver {
        match($0, /\(([^()]*)\)/, m);
        if (m[1] ~ /^com\.apple\.CoreSimulator\.SimRuntime\./) {
          print m[1];
          exit
        }
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
  # Lines look like:
  #   Apple TV (com.apple.CoreSimulator.SimDeviceType.Apple-TV-4K-1080p)
  DEVICE_TYPE_ID="$(
    xcrun simctl list devicetypes | \
    awk -v name="$DEVICE_NAME" -F '[()]' '
      # $1 is "Apple TV ", $2 is "com.apple.CoreSimulator.SimDeviceType.Apple-TV"
      $1 ~ name"[[:space:]]*$" {
        print $2;
        exit
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

# Optional: boot the device so xcodebuild doesn't have to
xcrun simctl boot "$DEVICE_NAME" || true
xcrun simctl bootstatus "$DEVICE_NAME" -b || true

echo "=== Devices for $PLATFORM $OS_VERSION after ensuring ==="
xcrun simctl list devices "$PLATFORM $OS_VERSION" || true
