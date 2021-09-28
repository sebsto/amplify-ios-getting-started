#!/bin/sh

AWS_CLI=/usr/local/bin/aws
REGION=$(curl -s 169.254.169.254/latest/meta-data/placement/region/)
HOME=/Users/ec2-user

pushd $HOME/amplify-ios-getting-started/code

# Increase Build Number
# https://rderik.com/blog/automating-build-and-testflight-upload-for-simple-ios-apps/

BUILD_NUMBER=`date +%Y%m%d%H%M%S`
plutil -replace CFBundleVersion -string $BUILD_NUMBER "./getting started/Info.plist"

KEYCHAIN_PASSWORD=Passw0rd
KEYCHAIN_NAME=dev.keychain

WORKSPACE="getting started.xcworkspace"
SCHEME="getting started"
CONFIGURATION="Release"
BUILD_PATH="./build"
ARCHIVE_PATH="$BUILD_PATH/getting-started.xcarchive"

security unlock-keychain -p $KEYCHAIN_PASSWORD $KEYCHAIN_NAME

xcodebuild clean archive                  \
           -workspace "$WORKSPACE"        \
           -scheme "$SCHEME"              \
           -archivePath "$ARCHIVE_PATH"   \
           -configuration "$CONFIGURATION"  >> /Users/ec2-user/log/build.log 2>&1
