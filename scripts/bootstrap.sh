#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

if ! command -v xcodegen >/dev/null 2>&1; then
    echo "xcodegen not found."
    if command -v brew >/dev/null 2>&1; then
        echo "Installing via Homebrew…"
        brew install xcodegen
    else
        echo "Please install XcodeGen: https://github.com/yonaskolb/XcodeGen" >&2
        exit 1
    fi
fi

echo "Generating WixPulse.xcodeproj…"
xcodegen generate

echo "Done. Open WixPulse.xcodeproj and run the WixPulse scheme."
