#!/bin/bash
set -e

echo "=== [1/4] Installing Flutter SDK on Vercel ==="
if [ ! -d "flutter" ]; then
  git clone --depth 1 --branch stable https://github.com/flutter/flutter.git flutter
else
  echo "Flutter directory already present."
fi

export PATH="$PATH:$(pwd)/flutter/bin"

echo "=== [2/4] Verifying Flutter ==="
flutter --version

echo "=== [3/4] Building Flutter Web (Release) ==="
flutter build web --release

echo "=== [4/4] Setting up Downloadable APK ==="
mkdir -p build/web/download
if [ -f "web/download/buoy-erp.apk" ]; then
  cp web/download/buoy-erp.apk build/web/download/buoy-erp.apk
  echo "✓ Copied release APK (web/download/buoy-erp.apk) to build/web/download/."
elif [ -f "build/app/outputs/flutter-apk/app-release.apk" ]; then
  cp build/app/outputs/flutter-apk/app-release.apk build/web/download/buoy-erp.apk
  echo "✓ Copied release APK from flutter-apk to build/web/download/."
fi

echo "=== Vercel Flutter Web Build Successful! ==="
