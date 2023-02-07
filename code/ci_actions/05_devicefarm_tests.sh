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

BUILD_PATH="./build"
APP_NAME="getting started"
DEVICE_FARM="device-farm"

xcodebuild build-for-testing                    \
           -workspace "${APP_NAME}.xcworkspace" \
           -scheme "${APP_NAME}"                \
           -destination generic/platform=iOS    \
           -derivedDataPath "${BUILD_PATH}"   | $BREW_PATH/xcbeautify

echo "Building Application UI Tests IPA file"
rm -rf "${DEVICE_FARM}"
mkdir -p "${DEVICE_FARM}/Payload"
cp -r "${BUILD_PATH}/Build/Products/Debug-iphoneos/${APP_NAME} ui tests-Runner.app" "${DEVICE_FARM}/Payload"
(cd ${DEVICE_FARM} && zip -r "${APP_NAME}-UI.ipa" Payload)

echo "Building Application IPA file"
rm -rf "${DEVICE_FARM}/Payload"
mkdir -p "${DEVICE_FARM}/Payload"
cp -r "${BUILD_PATH}/Build/Products/Debug-iphoneos/${APP_NAME}.app" "${DEVICE_FARM}/Payload"
(cd ${DEVICE_FARM} && zip -r "${APP_NAME}.ipa" Payload)
rm -rf "${DEVICE_FARM}/Payload"

popd
