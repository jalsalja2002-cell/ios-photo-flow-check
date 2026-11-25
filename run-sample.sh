#!/bin/bash
set -euo pipefail

root="$(cd "$(dirname "$0")" && pwd)"
maestro_bin="${MAESTRO_BIN:-maestro}"
device_type="${PHOTO_FLOW_DEVICE_TYPE:-com.apple.CoreSimulator.SimDeviceType.iPhone-17}"
runtime="${PHOTO_FLOW_RUNTIME:-com.apple.CoreSimulator.SimRuntime.iOS-27-0}"
bundle_id="com.lumoscode.photoflow.sample"

if ! command -v "$maestro_bin" >/dev/null; then
  echo "Install Maestro or set MAESTRO_BIN to its executable." >&2
  exit 1
fi
if [[ -n "${JAVA_HOME:-}" ]]; then
  java_bin="$JAVA_HOME/bin/java"
else
  java_bin="java"
fi
"$java_bin" -version
"$maestro_bin" check-syntax "$root/flows/photo-result.yaml"
sdk="$(xcrun --sdk iphonesimulator --show-sdk-path)"
arch="$(uname -m)"
work="$(mktemp -d "${TMPDIR:-/tmp}/photo-flow-sample.XXXXXX")"
app="$work/PhotoFlowSample.app"
mkdir -p "$app" "$work/module-cache"
cp "$root/SampleInfo.plist" "$app/Info.plist"

xcrun --sdk iphonesimulator swiftc -parse-as-library \
  -target "$arch-apple-ios17.0-simulator" -sdk "$sdk" \
  -module-cache-path "$work/module-cache" "$root/PhotoFlowSample.swift" \
  -o "$app/PhotoFlowSample"
codesign --force --sign - "$app"
echo "Run reports: $work"

simulator="$(xcrun simctl create "Photo Flow Sample ${work##*.}" "$device_type" "$runtime")"
cleanup() {
  local result=$?
  trap - EXIT
  if (( result == 0 )); then
    xcrun simctl shutdown "$simulator" >/dev/null 2>&1 || true
    if ! xcrun simctl delete "$simulator"; then
      echo "Could not remove the sample simulator: $simulator" >&2
    fi
  else
    echo "Run failed. The new sample simulator was kept for diagnosis: $simulator" >&2
  fi
  exit "$result"
}
trap cleanup EXIT

xcrun simctl boot "$simulator"
xcrun simctl bootstatus "$simulator" -b
xcrun simctl install "$simulator" "$app"
xcrun simctl addmedia "$simulator" "$root/test-photo.png"

"$maestro_bin" test --platform ios --udid "$simulator" --no-ansi \
  --format junit --output "$work/junit.xml" --debug-output "$work/debug" \
  -e APP_ID="$bundle_id" \
  -e PICK_PHOTO_ID=pick-photo \
  -e SAMPLE_PICKER=true -e FIXTURE_SELECTOR='^$' \
  -e PREVIEW_ID=selected-photo-preview \
  -e GENERATE_ID=generate \
  -e GENERATED_RESULT_ID=generated-result \
  -e GALLERY_ID=open-gallery \
  -e RESULT_ROW_ID=gallery-result-test-fixture \
  -e REOPENED_RESULT_ID=reopened-result \
  "$root/flows/photo-result.yaml"
