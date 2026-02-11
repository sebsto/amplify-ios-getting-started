#!/bin/sh

#  ci_pre_xcodebuild.sh.sh
#  getting started
#
#  Created by Stormacq, Sebastien on 16/09/2022.
#  Copyright © 2022 Stormacq, Sebastien. All rights reserved.

# Set the -e flag to stop running the script in case a command returns
# a nonzero exit code.
set -e

export AWS_REGION=us-west-2
export CODE_DIR=/Volumes/workspace/repository/code

# The amplify app ID for this apps
# ⚠️⚠️⚠️ REPLACE WITH YOUR OWN APP ID IF YOU USE AMPLIFY ##
AMPLIFY_APP_ID=d199v9208momso

# Install Node.js if not present
if ! command -v node &> /dev/null; then
    echo "Installing Node.js via Homebrew"
    # Force v20 because of https://github.com/aws-amplify/amplify-cli/issues/14572
    HOMEBREW_NO_AUTO_UPDATE=1 brew install node@22
    export NODEJS22_PATH=/usr/local/opt/node@22/bin
    echo 'export PATH="$NODEJS22_PATH:$PATH"' >> ~/.zshrc

fi

# verify npm and npx are installed
if ! command -v ${NODEJS22_PATH}/npm &> /dev/null; then
    echo "🛑 npm not found, please install Node.js"
    exit 1
fi

if ! command -v ${NODEJS22_PATH}/npx &> /dev/null; then
    echo "🛑 npx not found, please install Node.js"
    exit 1
fi

# Verify Node.js installation
echo "Node.js version: $(${NODEJS22_PATH}/node --version)"
echo "npm version: $(${NODEJS22_PATH}/npm --version)"

echo "✅ npm and npx are available"

# Install AWS CLI if not present
if ! command -v aws &> /dev/null; then
    echo "Installing AWS CLI via Homebrew"
    brew install awscli
fi

# Verify AWS CLI installation
echo "AWS CLI version: $(aws --version)"
echo "✅ AWS CLI is available"

# Install Amplify Gen2 CLI
echo "Installing Amplify Gen2 CLI dependencies"
${NODEJS22_PATH}/npm install @aws-amplify/backend-cli@latest

# verify amplify app exists in the region
echo "Verifying Amplify app $AMPLIFY_APP_ID exists in region $AWS_REGION"
if ! aws amplify get-app --app-id $AMPLIFY_APP_ID --region $AWS_REGION &> /dev/null; then
    echo "🛑 Amplify app $AMPLIFY_APP_ID not found in region $AWS_REGION"
    exit 1
fi
echo "✅ Amplify app verified"

echo "Changing to code directory at $CODE_DIR"
pushd $CODE_DIR

# DO NOT USE NodeJS 25 with this !
# https://github.com/aws-amplify/amplify-cli/issues/14572

echo "Amplify generate outputs"
${NODEJS22_PATH}/npx ampx generate outputs    \
  --app-id ${AMPLIFY_APP_ID} \
  --branch main              \
  --out-dir .                \
  --format json

# A command or script succeeded.
echo "✅ Done."
popd

exit 0
