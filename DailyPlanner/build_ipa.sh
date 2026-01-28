#!/bin/bash
# =============================================================
# DailyPlanner - Build IPA Script
# =============================================================
# Prerequisites:
#   1. Xcode installed (15.0+)
#   2. Valid Apple Developer account signed in to Xcode
#   3. Update TEAM_ID in ExportOptions.plist with your Team ID
#
# Usage: ./build_ipa.sh
# =============================================================

set -e

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_PATH="$PROJECT_DIR/DailyPlanner.xcodeproj"
SCHEME="DailyPlanner"
ARCHIVE_PATH="$PROJECT_DIR/build/DailyPlanner.xcarchive"
EXPORT_PATH="$PROJECT_DIR/build/IPA"
EXPORT_OPTIONS="$PROJECT_DIR/ExportOptions.plist"

echo "================================================"
echo "  DailyPlanner - Building IPA"
echo "================================================"

# Step 1: Clean
echo ""
echo "[1/4] Cleaning build folder..."
xcodebuild clean \
    -project "$PROJECT_PATH" \
    -scheme "$SCHEME" \
    -configuration Release \
    2>&1 | tail -5

# Step 2: Archive
echo ""
echo "[2/4] Archiving project..."
xcodebuild archive \
    -project "$PROJECT_PATH" \
    -scheme "$SCHEME" \
    -configuration Release \
    -destination "generic/platform=iOS" \
    -archivePath "$ARCHIVE_PATH" \
    CODE_SIGN_STYLE=Automatic \
    2>&1 | tail -10

echo "Archive created at: $ARCHIVE_PATH"

# Step 3: Export IPA
echo ""
echo "[3/4] Exporting IPA..."
xcodebuild -exportArchive \
    -archivePath "$ARCHIVE_PATH" \
    -exportPath "$EXPORT_PATH" \
    -exportOptionsPlist "$EXPORT_OPTIONS" \
    2>&1 | tail -10

# Step 4: Done
echo ""
echo "[4/4] Build complete!"
echo ""
echo "================================================"
echo "  IPA file location:"
echo "  $EXPORT_PATH/DailyPlanner.ipa"
echo ""
echo "  To install on your iPad:"
echo "  1. Connect iPad via USB"
echo "  2. Open Finder (macOS Ventura+) or iTunes"
echo "  3. Drag the .ipa file onto your iPad"
echo "  OR"
echo "  Use: ios-deploy --bundle $EXPORT_PATH/DailyPlanner.ipa"
echo "  OR"
echo "  Use Apple Configurator 2"
echo "================================================"
