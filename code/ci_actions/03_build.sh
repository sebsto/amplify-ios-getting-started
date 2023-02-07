#!/bin/sh
set -e 
set -o pipefail

arch_name="$(uname -m)"
if [ ${arch_name} = "arm64" ]; then 
    BREW_PATH=/opt/homebrew/bin
    AWS_CLI=$BREW_PATH/aws
else
    BREW_PATH=/usr/local/bin
    AWS_CLI=$BREW_PATH/aws
fi

REGION=$(curl -s 169.254.169.254/latest/meta-data/placement/region/)
export LANG=en_US.UTF-8

if [ ! -z ${GITHUB_ACTION} ]; then # we are running from a github runner
    CODE_DIR=$GITHUB_WORKSPACE/code
fi
if [ ! -z ${CI_BUILDS_DIR} ]; then # we are running from a gitlab runner
    CODE_DIR=$CI_PROJECT_DIR/code
fi
if [ -z ${CODE_DIR} ]; then
    echo Neither GitLab nor GitHub detected. Where are we running ?
    exit -1 
fi

echo "Changing to code directory at $CODE_DIR"
pushd $CODE_DIR

KEYCHAIN_PASSWORD=Passw0rd
KEYCHAIN_NAME=dev.keychain

WORKSPACE="getting started.xcworkspace"
SCHEME="getting started"
CONFIGURATION="Release"
BUILD_PATH="./build"
ARCHIVE_PATH="$BUILD_PATH/getting-started.xcarchive"

security unlock-keychain -p $KEYCHAIN_PASSWORD $KEYCHAIN_NAME

xcodebuild clean archive                    \
           -workspace "$WORKSPACE"          \
           -scheme "$SCHEME"                \
           -archivePath "$ARCHIVE_PATH"     \
           -derivedDataPath "${BUILD_PATH}" \
           -configuration "$CONFIGURATION"   | $BREW_PATH/xcbeautify

popd