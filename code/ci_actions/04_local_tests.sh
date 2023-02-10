#!/bin/sh
set -e 
set -o pipefail

. code/ci_actions/00_common.sh

echo "Changing to code directory at $CODE_DIR"
pushd $CODE_DIR

WORKSPACE="getting started.xcworkspace"
SCHEME="getting started"
PHONE_MODEL="iPhone 14 Pro"
IOS_VERSION="16.2"

xcodebuild test \
    -workspace "$WORKSPACE" \
    -scheme "$SCHEME"       \
    -destination platform="iOS Simulator",name="${PHONE_MODEL}",OS=${IOS_VERSION}  | $BREW_PATH/xcbeautify

popd
