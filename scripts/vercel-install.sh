#!/usr/bin/env bash
# Installs the Flutter SDK inside the Vercel build container, then fetches
# packages. Vercel caches the project directory between builds, so the SDK is
# only downloaded on the first build (or when FLUTTER_VERSION changes).
set -euo pipefail

FLUTTER_VERSION="3.50.1"

if [ -d flutter ] && [ "$(cat flutter/version 2>/dev/null || git -C flutter describe --tags 2>/dev/null)" != "$FLUTTER_VERSION" ]; then
  rm -rf flutter
fi
if [ ! -d flutter ]; then
  git clone --depth 1 --branch "$FLUTTER_VERSION" https://github.com/flutter/flutter.git flutter
fi

export PATH="$PWD/flutter/bin:$PATH"
flutter config --no-analytics >/dev/null
flutter --version
flutter pub get
