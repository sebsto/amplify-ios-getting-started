#!/bin/sh

# Thanks to 
# https://medium.com/appssemble/a-guide-to-writing-your-own-ios-ci-cd-integration-script-186be1b99575

AWS_CLI=/usr/local/bin/aws
REGION=$(curl -s 169.254.169.254/latest/meta-data/placement/region/)
HOME=/Users/ec2-user
export LANG=en_US.UTF-8

pushd $HOME 
if [ -d amplify-ios-getting-started ]; then
    rm -rf amplify-ios-getting-started
fi
git clone https://github.com/sebsto/amplify-ios-getting-started.git
popd

CODE_DIR=$HOME/amplify-ios-getting-started/code
echo "Changing to code directory at $CODE_DIR"
pushd $CODE_DIR

echo "Installing pods"
/usr/local/bin/pod install

echo "Pulling amplify environment"

AMPLIFY_APPID_SECRET=amplify-app-id
AMPLIFY_PROJECT_NAME_SECRET=amplify-project-name
AMPLIFY_ENV_SECRET=amplify-environment
AMPLIFY_APPID=$($AWS_CLI --region $REGION secretsmanager get-secret-value --secret-id $AMPLIFY_APPID_SECRET --query SecretString --output text)
AMPLIFY_PROJECT_NAME=$($AWS_CLI --region $REGION secretsmanager get-secret-value --secret-id $AMPLIFY_PROJECT_NAME_SECRET --query SecretString --output text)
AMPLIFY_ENV=$($AWS_CLI --region $REGION secretsmanager get-secret-value --secret-id $AMPLIFY_ENV_SECRET --query SecretString --output text)  


AWSCLOUDFORMATIONCONFIG="{\
\"configLevel\":\"general\",\
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
PROVIDERS="{\
\"awscloudformation\":$AWSCLOUDFORMATIONCONFIG\
}"


PATH=$PATH:/usr/local/bin/ # require to find node
/usr/local/bin/amplify pull \
--amplify $AMPLIFY \
--frontend $FRONTEND \
--providers $PROVIDERS \
--yes --region $REGION


# echo "Generate code for application models"
/usr/local/bin/amplify codegen models 

# Increase Build Number
# https://rderik.com/blog/automating-build-and-testflight-upload-for-simple-ios-apps/

BUILD_NUMBER=`date +%Y%m%d%H%M%S`
plutil -replace CFBundleVersion -string $BUILD_NUMBER "./getting started/Info.plist"
