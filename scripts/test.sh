#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p work
swiftc NorthCompass/CompassMath.swift Tests/main.swift -o work/compass-tests
work/compass-tests
