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

BUILD_PATH="./build"
APP_NAME="getting started"
DEVICE_FARM="device-farm"

xcodebuild build-for-testing                    \
           -workspace "${APP_NAME}.xcworkspace" \
           -scheme "${APP_NAME}"                \
           -destination generic/platform=iOS    \
           -derivedDataPath "${BUILD_PATH}"   | xcbeautify

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
