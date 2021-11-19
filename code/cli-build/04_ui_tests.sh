#!/bin/sh
set -e 
set -o pipefail

AWS_CLI=/usr/local/bin/aws
REGION=$(curl -s 169.254.169.254/latest/meta-data/placement/region/)
HOME=/Users/ec2-user

BUILD_PATH="./build"
APP_NAME="getting started"
DEVICE_FARM="device-farm"

pushd $HOME/amplify-ios-getting-started/code

xcodebuild build-for-testing                    \
           -workspace "${APP_NAME}.xcworkspace" \
           -scheme "${APP_NAME}"                \
           -destination generic/platform=iOS    \
           -derivedDataPath "${BUILD_PATH}" >> /Users/ec2-user/log/build-for-testing.log 2>&1

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

###############
#
# Device Farm 
#
###############

exit 0 

pushd $HOME/amplify-ios-getting-started/code

# device farm is only available in us-west-2 
REGION=us-west-2 


#TODO move this to secrets manager 
PROJECT_ARN="arn:aws:devicefarm:us-west-2:486652066693:project:a8cc6b43-ba3b-4b93-9bd9-1800c99f9118"

APP_BUNDLE="${APP_NAME}.ipa"
TEST_BUNDLE="${APP_NAME}-UI.ipa"
FILE_APP_BUNDLE="${DEVICE_FARM}/${APP_NAME}.ipa"
FILE_TEST_BUNDLE="${DEVICE_FARM}/${APP_NAME}-UI.ipa"

## Upload app
echo "Preparing App upload to Device Farm"
app_upload_output=$(${AWS_CLI} devicefarm create-upload --region ${REGION} --project-arn ${PROJECT_ARN} --name ${APP_BUNDLE} --type IOS_APP)
app_s3_upload_url=$(echo $app_upload_output | jq -r '.upload.url')
app_upload_arn=$(echo $app_upload_output | jq -r '.upload.arn')

echo "Uploading app"
curl -T "${FILE_APP_BUNDLE}" "$app_s3_upload_url"

echo "Printing app upload status";
echo "";
aws devicefarm --region ${REGION}  get-upload --arn ${app_upload_arn}

## Upload Test
echo "Preparing Test upload to Device Farm"
test_upload_output=$(aws devicefarm create-upload --region ${REGION}  --project-arn ${PROJECT_ARN} --name ${TEST_BUNDLE} --type XCTEST_UI_TEST_PACKAGE)
test_s3_upload_url=$(echo $test_upload_output | jq -r '.upload.url')
test_upload_arn=$(echo $test_upload_output | jq -r '.upload.arn')

echo "Uploading Test"
curl -T "${FILE_TEST_BUNDLE}" "$test_s3_upload_url"

echo "Printing test upload status";
echo "";
aws devicefarm get-upload --region ${REGION}  --arn ${test_upload_arn}

list_device_pools_output="$(aws devicefarm list-device-pools --region ${REGION} --arn ${PROJECT_ARN})";
echo "Printing device pools";
echo "";
echo $list_device_pools_output | python -m json.tool

top_device_pool_arn="$(echo $list_device_pools_output | jq -r '.devicePools[0].arn')";
top_device_pool_description="$(echo $list_device_pools_output | jq -r '.devicePools[0].description')";

echo "Printing top device pool arn";
echo "";
echo $top_device_pool_arn

echo "Printing top device pool description";
echo "";
echo $top_device_pool_description

test_specs_output="$(aws devicefarm list-uploads --region ${REGION} --arn ${PROJECT_ARN})";
echo "Printing all uploads";
echo "";
echo $test_specs_output | python -m json.tool

#This is the ARN for the default IOS Test environment on device farm
IOS_TEST_SPEC_ARN=$(aws devicefarm list-uploads --region ${REGION} --arn ${PROJECT_ARN} --query "uploads[?type==\`XCTEST_UI_TEST_SPEC\`].arn" --output text)

## Schedule a run on Device Farm
schedule_run_output="$(aws devicefarm schedule-run --project-arn ${PROJECT_ARN} --app-arn ${app_upload_arn} --device-pool-arn ${top_device_pool_arn} --name CLITestRun --test type=APPIUM_JAVA_TESTNG,testPackageArn=${test_upload_arn},testSpecArn=${IOS_TEST_SPEC_ARN})";
echo "Printing schedule run output";
echo "";
echo $schedule_run_output | python -m json.tool

# Forloop to test is run is complete 
## calling get-run command

popd