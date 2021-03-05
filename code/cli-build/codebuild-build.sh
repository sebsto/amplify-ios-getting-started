#!/bin/sh

source ./build_secrets.sh

echo "Build, Sign and Archive"
SCHEME="getting started"
CONFIGURATION="Release"
WORKSPACE="getting started.xcworkspace"
BUILD_PATH="./build"
ARCHIVE_PATH="$BUILD_PATH/getting-started.xcarchive"
EXPORT_OPTIONS="./cli-build/ExportOptions.plist"
xcodebuild clean build archive \
           -workspace "$WORKSPACE" \
           -scheme "$SCHEME" \
           -archivePath "$ARCHIVE_PATH" \
           -configuration "$CONFIGURATION" 