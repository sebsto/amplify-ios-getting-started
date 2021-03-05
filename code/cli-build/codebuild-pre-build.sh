#!/bin/sh


# Thanks to 
# https://medium.com/appssemble/a-guide-to-writing-your-own-ios-ci-cd-integration-script-186be1b99575


CODE_DIR=$HOME/amplify-ios-getting-started/code
echo "Changing to code directory at $CODE_DIR"
cd $CODE_DIR
source $CODE_DIR/cli-build/codebuild-configuration.sh

echo "Installing pods"
/usr/local/bin/pod install

echo "Backing up generated files (these are deleted by amplify pull)"
mv amplify/generated .

echo "Pulling amplify environment"

# see https://docs.amplify.aws/cli/usage/headless#amplify-pull-parameters 

AWSCLOUDFORMATIONCONFIG="{\
\"configLevel\":\"project\",\
\"useProfile\":true,\
\"profileName\":\"default\"\
}"
AMPLIFY="{\
\"projectName\":\"$AMPLIFY_PROJECT_NAME\",\
\"appId\":\"$AMPLIFY_APPID\",\
\"envName\":\"$AMPLIFY_ENV\",\
\"defaultEditor\":\"code\"\
}"
FRONTEND="{\
\"frontend\":\"ios\"
}"

PATH=$PATH:/usr/local/bin/ # require to find node
/usr/local/bin/amplify pull \
--amplify $AMPLIFY \
--frontend $FRONTEND \
--providers $PROVIDERS \
--yes --region eu-central-1

echo "Restore generated files"
mv ./generated amplify/

# Increase Build Number
# https://rderik.com/blog/automating-build-and-testflight-upload-for-simple-ios-apps/

BUILD_NUMBER=`date +%Y%m%d%H%M%S`
plutil -replace CFBundleVersion -string $BUILD_NUMBER "./getting started/Info.plist"


