#!/bin/sh
set -e 
set -o pipefail

. code/ci_actions/00_common.sh

echo "Changing to code directory at $CODE_DIR"
pushd $CODE_DIR

PROJECT="getting started.xcodeproj"
SCHEME="getting started"
CONFIGURATION="Debug"
BUILD_PATH="./build-test"
PHONE_MODEL="iPhone 17 Pro"
IOS_VERSION="26.2"

xcodebuild clean test \
    -project "$PROJECT"     \
    -scheme "$SCHEME"       \
    -configuration "$CONFIGURATION" \
    -derivedDataPath "${BUILD_PATH}" \
    -destination platform="iOS Simulator",name="${PHONE_MODEL}",OS=${IOS_VERSION}  | $BREW_PATH/xcbeautify

popd
