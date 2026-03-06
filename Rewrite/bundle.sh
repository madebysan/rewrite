#!/bin/bash
# Bundle the Swift Package Manager executable into a macOS .app

set -e

APP_NAME="Rewrite"
BUILD_DIR=".build/debug"
APP_BUNDLE="$BUILD_DIR/$APP_NAME.app"
CONTENTS="$APP_BUNDLE/Contents"
MACOS="$CONTENTS/MacOS"

# Build first
swift build

# Create .app bundle structure
rm -rf "$APP_BUNDLE"
mkdir -p "$MACOS"

# Copy executable
cp "$BUILD_DIR/$APP_NAME" "$MACOS/$APP_NAME"

# Copy Info.plist
cp "Sources/Rewrite/Resources/Info.plist" "$CONTENTS/Info.plist"

echo "Built $APP_BUNDLE"
echo "Run with: open $APP_BUNDLE"
