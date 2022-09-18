#!/bin/sh
set -e 
set -o pipefail

arch_name="$(uname -m)"
if [ ${arch_name} = "arm64" ]; then 
    AWS_CLI=/opt/homebrew/bin/aws
else
    AWS_CLI=/usr/local/bin/aws 
fi
REGION=$(curl -s 169.254.169.254/latest/meta-data/placement/region/)
CODE_DIR=/Users/ec2-user/actions-runner/_work/amplify-ios-getting-started/code
export LANG=en_US.UTF-8
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
           -configuration "$CONFIGURATION"  

popd