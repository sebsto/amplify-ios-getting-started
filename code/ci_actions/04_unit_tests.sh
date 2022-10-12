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
CODE_DIR=/Users/ec2-user/actions-runner/_work/amplify-ios-getting-started/amplify-ios-getting-started/code
export LANG=en_US.UTF-8
echo "Changing to code directory at $CODE_DIR"
pushd $CODE_DIR

WORKSPACE="getting started.xcworkspace"
SCHEME="getting started"
#PHONE_MODEL="iPhone 14"
#IOS_VERSION="16.0"
PHONE_MODEL="iPhone 13"
IOS_VERSION="15.5"

xcodebuild test \
    -workspace "$WORKSPACE" \
    -scheme "$SCHEME"       \
    -destination platform="iOS Simulator",name="${PHONE_MODEL}",OS=${IOS_VERSION}  | xcbeautify

popd
