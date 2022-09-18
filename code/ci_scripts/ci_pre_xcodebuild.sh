#!/bin/sh

#  ci_pre_xcodebuild.sh.sh
#  getting started
#
#  Created by Stormacq, Sebastien on 16/09/2022.
#  Copyright © 2022 Stormacq, Sebastien. All rights reserved.

# Set the -e flag to stop running the script in case a command returns
# a nonzero exit code.
set -e

echo "🍜 Prepare AWS CLI configuration"
AMPLIFY_REGION=eu-central-1
mkdir ~/.aws
echo "[default]\nregion=$AMPLIFY_REGION\n\n" > ~/.aws/config
echo "[default]\n\n" > ~/.aws/credentials

echo "🏗 Installing Amplify"
curl -sL https://aws-amplify.github.io/amplify-cli/install | bash && $SHELL

echo "💫 Configuring Amplify for this project"
AMPLIFY_APPID="d1lld0ga9eqxz2"
AMPLIFY_PROJECT_NAME="iOSGettingStarted"
AMPLIFY_ENV="dev"

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

pushd /Volumes/workspace/repository/code
~/.amplify/bin/amplify pull \
--region $AMPLIFY_REGION \
--amplify $AMPLIFY       \
--frontend $FRONTEND     \
--providers $PROVIDERS   \
--yes

echo "💫 Generating code"
~/.amplify/bin/amplify codegen models
# Not necessary to copy the files. Xcode project has a folder pointing to amplify/generated/models
# cp amplify/generated/models/*.swift "getting started"

# A command or script succeeded.
echo "✅ Done."
popd

exit 0
