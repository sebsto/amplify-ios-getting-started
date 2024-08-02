#!/bin/sh
set -e 
set -o pipefail

. code/ci_actions/00_common.sh

echo "Changing to code directory at $CODE_DIR"
pushd $CODE_DIR

PROJECT="getting started.xcodeproj"
SCHEME="getting started"
PHONE_MODEL="iPhone 15 Pro"
IOS_VERSION="17.5"

xcodebuild test \
    -project "$PROJECT"     \
    -scheme "$SCHEME"       \
    -destination platform="iOS Simulator",name="${PHONE_MODEL}",OS=${IOS_VERSION}  | $BREW_PATH/xcbeautify

popd
