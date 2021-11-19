#!/bin/sh
set -e 
set -o pipefail

AWS_CLI=/usr/local/bin/aws
REGION=$(curl -s 169.254.169.254/latest/meta-data/placement/region/)
HOME=/Users/ec2-user

pushd $HOME/amplify-ios-getting-started/code

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
           -configuration "$CONFIGURATION"  >> /Users/ec2-user/log/build.log 2>&1

popd