#!/bin/sh

set -e 
set -o pipefail

APP_NAME="getting started"
DEVICE_FARM="device-farm"
BUILD_DIR="build_for_testing"

#rm -rf ${DEVICE_FARM} && rm -rf ${BUILD_DIR}
xcodebuild -workspace "${APP_NAME}.xcworkspace" -scheme "${APP_NAME}" -destination generic/platform=iOS build-for-testing -derivedDataPath "${BUILD_DIR}"

echo "Building Application UI Tests IPA file"
rm -rf "${DEVICE_FARM}/Payload"
mkdir -p "${DEVICE_FARM}/Payload"
cp -r "${BUILD_DIR}/Build/Products/Debug-iphoneos/${APP_NAME} ui tests-Runner.app" "${DEVICE_FARM}/Payload"
(cd ${DEVICE_FARM} && zip -r "${APP_NAME}-UI.ipa" Payload)

echo "Building Application IPA file"
rm -rf "${DEVICE_FARM}/Payload"
mkdir -p "${DEVICE_FARM}/Payload"
cp -r "${BUILD_DIR}/Build/Products/Debug-iphoneos/${APP_NAME}.app" "${DEVICE_FARM}/Payload"
(cd ${DEVICE_FARM} && zip -r "${APP_NAME}.ipa" Payload)
rm -rf "${DEVICE_FARM}/Payload"
