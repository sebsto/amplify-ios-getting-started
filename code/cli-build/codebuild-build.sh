#!/bin/sh

CODE_DIR=$HOME/amplify-ios-getting-started/code
echo "Changing to code directory at $CODE_DIR"
cd $CODE_DIR
source ./cli-build/codebuild-configuration.sh

echo "Build and Sign"

xcodebuild clean build archive \
           -workspace "$WORKSPACE" \
           -scheme "$SCHEME" \
           -archivePath "$ARCHIVE_PATH" \
           -configuration "$CONFIGURATION" 