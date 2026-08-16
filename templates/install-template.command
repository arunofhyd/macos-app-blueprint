#!/usr/bin/env bash
# =============================================================================
#  __APP_NAME__ — Builder & Installer Template
#  Built by Arun Thomas · https://github.com/arunofhyd/__APPNAME__
#
#  Builds the app LOCALLY on your Mac so Gatekeeper trusts it automatically.
# =============================================================================

set -e

APP_NAME="__APP_NAME__"
BUNDLE_NAME="__APP_NAME__.app"
REPO_RAW="https://raw.githubusercontent.com/USERNAME/__APPNAME__/main"

# ── Terminal Styling ──
BOLD='\033[1m'; DIM='\033[2m'; NC='\033[0m'
ORANGE='\033[38;5;208m'; GREEN='\033[38;5;35m'; YELLOW='\033[38;5;220m'; RED='\033[38;5;196m'; GREY='\033[38;5;245m'

line() { printf "${DIM}────────────────────────────────────────────────────────────${NC}\n"; }
step() { printf "${ORANGE}${BOLD}▸${NC} ${BOLD}%s${NC}\n" "$1"; }
ok()   { printf "  ${GREEN}✓${NC} %s\n" "$1"; }
warn() { printf "  ${YELLOW}!${NC} %s\n" "$1"; }
fail() { printf "  ${RED}✗ %s${NC}\n" "$1"; }

if [ "$CI" != "true" ]; then clear; fi

printf "\n"
printf "${ORANGE}${BOLD}   ${APP_NAME}${NC}\n"
printf "${GREY}   __TAGLINE__${NC}\n"
printf "${GREY}   Built with ❤️ by Arun Thomas · https://github.com/arunofhyd/__APPNAME__${NC}\n\n"
line
printf "\n"

# ── Step 1: Xcode Command Line Tools ──
step "Checking build tools..."
if ! xcode-select -p >/dev/null 2>&1; then
    warn "Apple's Command Line Tools are needed to build the app."
    xcode-select --install >/dev/null 2>&1
    printf "  ${YELLOW}When installation is COMPLETE, press [Enter] to continue...${NC}"
    read -r
    while ! xcode-select -p >/dev/null 2>&1; do
        printf "  ${GREY}Waiting for installation...${NC}\n"
        sleep 5
    done
fi
ok "Swift compiler available ($(swiftc --version | head -n1))"

# ── Step 2: Dependencies ──
# Add Python/Node/etc checks here as needed
# Example:
# step "Checking Python..."
# PYTHON_BIN=$(which python3 2>/dev/null || echo "/usr/bin/python3")
# ok "Python available ($PYTHON_BIN)"

# ── Step 3: Source Setup ──
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd)"
BUILD_DIR=""

if [ -f "$SCRIPT_DIR/__APP_NAME__.swift" ] && [ -f "$SCRIPT_DIR/Info.plist" ]; then
    step "Building from local repository..."
    BUILD_DIR="$SCRIPT_DIR/Build"
    SRC_DIR="$SCRIPT_DIR"
else
    step "Downloading latest source from GitHub..."
    WORK_DIR="$(mktemp -d /tmp/__appname___build_XXXXXX)"
    SRC_DIR="$WORK_DIR"
    BUILD_DIR="$WORK_DIR/Build"

    curl -fsSL "$REPO_RAW/__APP_NAME__.swift" -o "$SRC_DIR/__APP_NAME__.swift"
    curl -fsSL "$REPO_RAW/Info.plist" -o "$SRC_DIR/Info.plist"
    curl -fsSL "$REPO_RAW/version.json" -o "$SRC_DIR/version.json" 2>/dev/null || true
    curl -fsSL "$REPO_RAW/AppIcon.icns" -o "$SRC_DIR/AppIcon.icns" 2>/dev/null || true
    curl -fsSL "$REPO_RAW/AppLogo.png" -o "$SRC_DIR/AppLogo.png" 2>/dev/null || true
    curl -fsSL "$REPO_RAW/AppIcon.png" -o "$SRC_DIR/AppIcon.png" 2>/dev/null || true
    curl -fsSL "$REPO_RAW/logo.svg" -o "$SRC_DIR/logo.svg" 2>/dev/null || true
fi

mkdir -p "$BUILD_DIR"
APP_TARGET="$BUILD_DIR/$BUNDLE_NAME"

# ── Step 4: Compile ──
step "Compiling Native SwiftUI Application..."
swiftc -O -parse-as-library "$SRC_DIR/__APP_NAME__.swift" -o "$BUILD_DIR/__APP_NAME__"
ok "Compiled native binary"

# ── Step 5: Bundle ──
step "Packaging $BUNDLE_NAME..."
rm -rf "$APP_TARGET"
mkdir -p "$APP_TARGET/Contents/MacOS" "$APP_TARGET/Contents/Resources"

# Read version from version.json
VERSION=$(python3 -c "import json, os; p='$SRC_DIR/version.json'; print(json.load(open(p))['version']) if os.path.exists(p) else print('1.0.0')" 2>/dev/null || echo "1.0.0")

cp "$BUILD_DIR/__APP_NAME__" "$APP_TARGET/Contents/MacOS/__APP_NAME__"
cp "$SRC_DIR/Info.plist" "$APP_TARGET/Contents/Info.plist"

# Stamp version from version.json
/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $VERSION" "$APP_TARGET/Contents/Info.plist" 2>/dev/null || true
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion $VERSION" "$APP_TARGET/Contents/Info.plist" 2>/dev/null || true

# Copy resources
cp "$SRC_DIR/AppIcon.icns" "$APP_TARGET/Contents/Resources/" 2>/dev/null || true
cp "$SRC_DIR/AppLogo.png" "$APP_TARGET/Contents/Resources/" 2>/dev/null || true
cp "$SRC_DIR/AppIcon.png" "$APP_TARGET/Contents/Resources/" 2>/dev/null || true
cp "$SRC_DIR/logo.svg" "$APP_TARGET/Contents/Resources/" 2>/dev/null || true

chmod +x "$APP_TARGET/Contents/MacOS/__APP_NAME__"
ok "App bundle v$VERSION assembled"

# ── CI mode: stop here ──
if [ "$CI" = "true" ]; then
    printf "\n${GREEN}${BOLD}✓ CI Build Complete!${NC}\n\n"
    exit 0
fi

# ── Step 6: Interactive GUI Installer ──
step "Launching interactive installation..."

# The InstallerGUI.swift heredoc goes here
# See templates/InstallerGUI.swift for the full GUI code
# Inline it with: cat << 'EOF' > "$BUILD_DIR/InstallerGUI.swift"

printf "\n${GREEN}${BOLD}✓ Build Complete!${NC}\n"
printf "${GREY}  App is at: ${APP_TARGET}${NC}\n\n"
