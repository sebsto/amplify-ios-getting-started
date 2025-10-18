#!/bin/sh
# set -x
set -e 
set -o pipefail

. code/ci_actions/00_common.sh

# The amplify app ID for this apps
# ⚠️⚠️⚠️ REPLACE WITH YOUR OWN APP ID IF YOU USE AMPLIFY ##
AMPLIFY_APP_ID=d199v9208momso

# verify npm and npx are installed
if ! command -v npm &> /dev/null; then
    echo "🛑 npm not found, please install Node.js"
    exit 1
fi

if ! command -v npx &> /dev/null; then
    echo "🛑 npx not found, please install Node.js"
    exit 1
fi

echo "✅ npm and npx are available"

# Install Amplify Gen2 CLI
echo "Installing Amplify Gen2 CLI dependencies"
npm install @aws-amplify/backend-cli@latest

# verify amplify app exists in the region
echo "Verifying Amplify app $AMPLIFY_APP_ID exists in region $AWS_REGION"
if ! aws amplify get-app --app-id $AMPLIFY_APP_ID --region $AWS_REGION &> /dev/null; then
    echo "🛑 Amplify app $AMPLIFY_APP_ID not found in region $AWS_REGION"
    exit 1
fi
echo "✅ Amplify app verified"

echo "Changing to code directory at $CODE_DIR"
pushd $CODE_DIR

npx ampx generate outputs    \
  --app-id ${AMPLIFY_APP_ID} \
  --branch main              \
  --out-dir ./code           \
  --format json

popd
