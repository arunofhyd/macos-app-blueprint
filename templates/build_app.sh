#!/usr/bin/env bash
# =============================================================================
#  build_app.sh — Fast Local Development & Bundle Builder
# =============================================================================
set -e

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
APP_NAME="__APP_NAME__"
APP_TARGET="$HOME/Downloads/$APP_NAME.app"

# 1. Single Source of Truth: Read version from version.json
VERSION=$(python3 -c "import json, os; p = '$DIR/version.json'; print(json.load(open(p))['version'])" 2>/dev/null || echo "1.0.0")
echo "🔖 Building $APP_NAME v$VERSION..."

# 2. Compile SwiftUI / AppKit binary
echo "🔨 Compiling Swift Binary..."
swiftc -O -parse-as-library "$DIR/$APP_NAME.swift" -o "$DIR/$APP_NAME"

# 3. Assemble .app bundle
echo "📦 Assembling .app bundle at $APP_TARGET..."
rm -rf "$APP_TARGET"
mkdir -p "$APP_TARGET/Contents/MacOS"
mkdir -p "$APP_TARGET/Contents/Resources"

cp "$DIR/$APP_NAME" "$APP_TARGET/Contents/MacOS/$APP_NAME"
cp "$DIR/Info.plist" "$APP_TARGET/Contents/Info.plist"

# 4. Stamp Info.plist with PlistBuddy
/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $VERSION" "$APP_TARGET/Contents/Info.plist" 2>/dev/null || \
/usr/libexec/PlistBuddy -c "Add :CFBundleShortVersionString string $VERSION" "$APP_TARGET/Contents/Info.plist" 2>/dev/null || true

/usr/libexec/PlistBuddy -c "Set :CFBundleVersion $VERSION" "$APP_TARGET/Contents/Info.plist" 2>/dev/null || \
/usr/libexec/PlistBuddy -c "Add :CFBundleVersion string $VERSION" "$APP_TARGET/Contents/Info.plist" 2>/dev/null || true

# 5. Copy brand assets & helper scripts
cp "$DIR/AppIcon.icns" "$APP_TARGET/Contents/Resources/" 2>/dev/null || true
cp "$DIR/AppLogo.png" "$APP_TARGET/Contents/Resources/" 2>/dev/null || true
cp "$DIR/AppIcon.png" "$APP_TARGET/Contents/Resources/" 2>/dev/null || true
cp "$DIR/logo.svg" "$APP_TARGET/Contents/Resources/" 2>/dev/null || true

chmod +x "$APP_TARGET/Contents/MacOS/$APP_NAME"

echo "✨ Native macOS App $APP_NAME v$VERSION successfully built!"
