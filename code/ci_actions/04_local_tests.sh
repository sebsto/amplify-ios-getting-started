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
export LANG=en_US.UTF-8

if [ ! -z ${GITHUB_ACTION} ]; then #we are running from a github runner
    CODE_DIR=$GITHUB_WORKSPACE/code
fi
if [ ! -z ${CI_BUILDS_DIR} ]; then #we are running from a gitlab runner
    CODE_DIR=$CI_PROJECT_DIR/code
fi
if [ -z ${CODE_DIR} ]; then
    echo Neither GitLab nor GitHub detected. Where are we running ?
    exit -1 
fi

echo "Changing to code directory at $CODE_DIR"
pushd $CODE_DIR

WORKSPACE="getting started.xcworkspace"
SCHEME="getting started"
PHONE_MODEL="iPhone 14 Pro"
IOS_VERSION="16.2"

xcodebuild test \
    -workspace "$WORKSPACE" \
    -scheme "$SCHEME"       \
    -destination platform="iOS Simulator",name="${PHONE_MODEL}",OS=${IOS_VERSION}  | xcbeautify

popd
