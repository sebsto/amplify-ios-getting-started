#!/bin/sh
set -e 
set -o pipefail

function upload_bundle() {
    local TYPE=$1
    local FILE=$2
    
    echo "Preparing an upload to Device Farm"
    local UPLOAD_NAME=$(basename "${FILE}")
    local UPLOAD_OUTPUT=$(${AWS_CLI} devicefarm create-upload --region ${REGION} --project-arn ${PROJECT_ARN} --name "${UPLOAD_NAME}" --type ${TYPE})
    local S3_UPLOAD_URL=$(echo $UPLOAD_OUTPUT | $BREW_PATH/jq -r '.upload.url')
    local UPLOAD_ARN=$(echo $UPLOAD_OUTPUT | $BREW_PATH/jq -r '.upload.arn')

    echo "Uploading"
    curl -T "$FILE" "$S3_UPLOAD_URL" 2>/dev/null

    echo "Waiting for upload status"
    local TEST_UPLOAD_STATUS=$(${AWS_CLI} devicefarm --region ${REGION} get-upload --arn ${UPLOAD_ARN} --no-cli-pager --query upload.status --output text)
    local ATTEMPT=0
    local WAIT_TIME=1
    while [ "$TEST_UPLOAD_STATUS" == "PROCESSING" ] || [ "$TEST_UPLOAD_STATUS" == "INITIALIZED" ] && [ "$ATTEMPT" -lt 5 ];
    do
        sleep $WAIT_TIME

        TEST_UPLOAD_STATUS=$(${AWS_CLI} devicefarm --region ${REGION} get-upload --arn ${UPLOAD_ARN} --no-cli-pager --query upload.status --output text)
        echo "Test upload status : $TEST_UPLOAD_STATUS"

        WAIT_TIME=$(( WAIT_TIME * 2 ))
        ATTEMPT=$(( ATTEMPT + 1 ))
    done
    
    if [ "$TEST_UPLOAD_STATUS" != "SUCCEEDED" ];
    then
        echo "Failed to upload file: ${FILE}"
        echo $(${AWS_CLI} devicefarm --region ${REGION} get-upload --arn ${UPLOAD_ARN} --no-cli-pager)
        exit -1
    fi

    echo "Get file upload ARN"
    RETURN_VALUE=$(${AWS_CLI} devicefarm --region ${REGION} get-upload --arn ${UPLOAD_ARN} --no-cli-pager --query upload.arn --output text)
}

function wait_test_complete() {
    local ARN=$1
    
    echo "Waiting for test to complete"
    local TEST_RUN_OUTPUT=$(${AWS_CLI} devicefarm --region ${REGION} get-run --arn ${ARN} --no-cli-pager)
    local TEST_RUN_STATUS=$(echo $TEST_RUN_OUTPUT | $BREW_PATH/jq -r '.run.status')
    local TEST_RUN_RESULT=$(echo $TEST_RUN_OUTPUT | $BREW_PATH/jq -r '.run.result')
    local ATTEMPT=0
    local MAX_ATTEMPT=30
    local WAIT_TIME=60
    while [ "$TEST_RUN_STATUS" != "COMPLETED" ] && [ "$ATTEMPT" -lt "$MAX_ATTEMPT" ];
    do
        echo "Waiting $WAIT_TIME seconds"
        sleep $WAIT_TIME

        TEST_RUN_OUTPUT=$(${AWS_CLI} devicefarm --region ${REGION} get-run --arn ${ARN} --no-cli-pager)
        TEST_RUN_STATUS=$(echo $TEST_RUN_OUTPUT | $BREW_PATH/jq -r '.run.status')
        TEST_RUN_RESULT=$(echo $TEST_RUN_OUTPUT | $BREW_PATH/jq -r '.run.result')
        echo "Test run status : $TEST_RUN_STATUS"

        ATTEMPT=$(( ATTEMPT + 1 ))
    done
    
    if [ "$TEST_RUN_RESULT" != "PASSED" ];
    then
        echo "Failed DeviceFarm tests"
        exit -1
    fi
}

# . code/ci_actions/00_common.sh

# echo "Changing to code directory at $CODE_DIR"
# pushd $CODE_DIR

# BUILD_PATH="./build-test"
# APP_NAME="getting started"
# DEVICE_FARM="./build-device-farm"

# echo "Build for testing"
# xcodebuild build-for-testing                    \
#            -workspace "${APP_NAME}.xcworkspace" \
#            -scheme "${APP_NAME}"                \
#            -destination generic/platform=iOS    \
#            -derivedDataPath "${BUILD_PATH}"   | $BREW_PATH/xcbeautify

# echo "Building Application UI Tests IPA file"
# rm -rf "${DEVICE_FARM}"
# mkdir -p "${DEVICE_FARM}/Payload"
# cp -r "${BUILD_PATH}/Build/Products/Debug-iphoneos/${APP_NAME} ui tests-Runner.app" "${DEVICE_FARM}/Payload"
# (cd ${DEVICE_FARM} && zip -r "${APP_NAME}-UI.ipa" Payload)

# echo "Building Application IPA file"
# rm -rf "${DEVICE_FARM}/Payload"
# mkdir -p "${DEVICE_FARM}/Payload"
# cp -r "${BUILD_PATH}/Build/Products/Debug-iphoneos/${APP_NAME}.app" "${DEVICE_FARM}/Payload"
# (cd ${DEVICE_FARM} && zip -r "${APP_NAME}.ipa" Payload)
# rm -rf "${DEVICE_FARM}/Payload"

# ###############
# #
# # Device Farm 
# #
# ###############

# # device farm is only available in us-west-2 
# REGION=us-west-2 

# # TODO move these to secrets manager ?
# PROJECT_ARN="arn:aws:devicefarm:us-west-2:486652066693:project:7fb4f0f3-2772-4123-97c0-d323084db635"
# PRIVATE_DEVICE_POOL_ARN="arn:aws:devicefarm:us-west-2:486652066693:devicepool:7fb4f0f3-2772-4123-97c0-d323084db635/0658c78b-8df7-439d-9785-e4f087dbcc55"

# APP_BUNDLE="${APP_NAME}.ipa"
# TEST_BUNDLE="${APP_NAME}-UI.ipa"
# FILE_APP_BUNDLE="${DEVICE_FARM}/${APP_NAME}.ipa"
# FILE_TEST_BUNDLE="${DEVICE_FARM}/${APP_NAME}-UI.ipa"
# FILE_TEST_SPEC="ci_actions/xctestui.yaml"

# ## Upload app
# echo "Uploading App"
# upload_bundle "IOS_APP" "${FILE_APP_BUNDLE}"
# IOS_APP_ARN=$RETURN_VALUE

# ## Upload Test
# echo "Uploading Test App"
# upload_bundle "XCTEST_UI_TEST_PACKAGE" "${FILE_TEST_BUNDLE}"
# IOS_TEST_APP_ARN=$RETURN_VALUE

# ## Upload Test Script
# echo "Preparing Test Script to Device Farm"
# upload_bundle "XCTEST_UI_TEST_SPEC"  "${FILE_TEST_SPEC}"
# IOS_TEST_SPEC_ARN=$RETURN_VALUE

## Schedule a run on Device Farm
# SCHEDULE_RUN_OUTPUT="$(${AWS_CLI} devicefarm schedule-run --region ${REGION}  \
#                                                           --project-arn ${PROJECT_ARN} \
#                                                           --app-arn ${IOS_APP_ARN} \
#                                                           --device-pool-arn ${PRIVATE_DEVICE_POOL_ARN} \
#                                                           --name CLITestRun  \
#                                                           --test type=XCTEST_UI,testPackageArn=${IOS_TEST_APP_ARN},testSpecArn=${IOS_TEST_SPEC_ARN} )"


# # Forloop to test until run is complete 
# SCHEDULED_RUN_ARN=$(echo $SCHEDULE_RUN_OUTPUT | $BREW_PATH/jq -r '.run.arn')
# wait_test_complete $SCHEDULED_RUN_ARN

# popd
