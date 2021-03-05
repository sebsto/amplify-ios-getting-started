#!/bin/sh

source ./codebuild-configuration.sh

echo "Build, Sign and Archive"

xcodebuild clean build archive \
           -workspace "$WORKSPACE" \
           -scheme "$SCHEME" \
           -archivePath "$ARCHIVE_PATH" \
           -configuration "$CONFIGURATION" 