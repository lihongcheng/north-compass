#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
xcodebuild -project NorthCompass.xcodeproj -scheme NorthCompass \
  -configuration Debug -destination 'generic/platform=iOS' \
  -derivedDataPath work/DerivedData -allowProvisioningUpdates build
