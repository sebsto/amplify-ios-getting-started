#!/bin/sh

# see https://developer.apple.com/library/archive/documentation/IDEs/Conceptual/xcode_guide-continuous_integration/EnvironmentVariableReference.html 

CODE_DIR=$XCS_SOURCE_DIR/ios-getting-started/code
echo "Changing to code directory at $CODE_DIR"
cd $CODE_DIR

echo "Installing pods"
/usr/local/bin/pod install

echo "Backing up generated files (these are deleted by amplify pull)"
mv amplify/generated .

# ACCESS_KEY_ID=$(curl -s 169.254.169.254/latest/meta-data/iam/security-credentials/admin | jq -r .AccessKeyId)
# SECRET_ACCESS_KEY=$(curl -s 169.254.169.254/latest/meta-data/iam/security-credentials/admin | jq -r .SecretAccessKey)
# SESSION_TOKEN=$(curl -s 169.254.169.254/latest/meta-data/iam/security-credentials/admin | jq -r .Token)
# REGION=$(curl -s 169.254.169.254/latest/meta-data/placement/region/)

echo "Pulling amplify environment"

# see https://docs.amplify.aws/cli/usage/headless#amplify-pull-parameters 

AWSCLOUDFORMATIONCONFIG="{\
\"configLevel\":\"project\",\
\"useProfile\":true,\
\"profileName\":\"default\"\
}"
AMPLIFY="{\
\"projectName\":\"iosgettingstarted\",\
\"appId\":\"d3tdpju84wvt9p\",\
\"envName\":\"dev\",\
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
--yes

echo "Restore generated files"
mv ./generated amplify/