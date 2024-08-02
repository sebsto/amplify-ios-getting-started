#!/bin/sh
set -x
set -e 
set -o pipefail

. code/ci_actions/00_common.sh

# the region where the backend is deployed
BACKEND_REGION=eu-central-1 

# search for amplify 
AMPLIFY_STANDALONE=$HOME/.amplify/bin/amplify
AMPLIFY_BREW=/opt/homebrew/bin/amplify
if [ -f $AMPLIFY_STANDALONE ]; then
	AMPLIFY_CLI=$AMPLIFY_STANDALONE
elif [ -f $AMPLIFY_BREW ]; then
	AMPLIFY_CLI=$AMPLIFY_BREW
else
	echo "Amplify CLI not found, installing it"
	curl -sL https://aws-amplify.github.io/amplify-cli/install | bash && $SHELL
	if [ -f $AMPLIFY_STANDALONE ]; then
		AMPLIFY_CLI=$AMPLIFY_STANDALONE
	else
	  echo "🛑 Amplify CLI not found, abording"
		exit 1
	fi
fi

if [ -d "$HOME/.aws" ]; then
  echo "Backing up existing AWS CLI configuration"
	mv $HOME/.aws ~/.aws.bak
fi
echo "Prepare AWS CLI configuration"
mkdir $HOME/.aws
echo "[default]\nregion=$BACKEND_REGION\n\n" > ~/.aws/config
echo "[default]\n\n" > ~/.aws/credentials

echo "Using amplify at $AMPLIFY_CLI"
echo "Changing to code directory at $CODE_DIR"
pushd $CODE_DIR

echo "Retrieving secrets"

AMPLIFY_APPID_SECRET=amplify-app-id
AMPLIFY_PROJECT_NAME_SECRET=amplify-project-name
AMPLIFY_ENV_SECRET=amplify-environment
AMPLIFY_APPID=$($AWS_CLI --region $REGION secretsmanager get-secret-value --secret-id $AMPLIFY_APPID_SECRET --query SecretString --output text)
AMPLIFY_PROJECT_NAME=$($AWS_CLI --region $REGION secretsmanager get-secret-value --secret-id $AMPLIFY_PROJECT_NAME_SECRET --query SecretString --output text)
AMPLIFY_ENV=$($AWS_CLI --region $REGION secretsmanager get-secret-value --secret-id $AMPLIFY_ENV_SECRET --query SecretString --output text)  

echo "Pulling amplify environment"

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

$AMPLIFY_CLI pull \
--amplify $AMPLIFY \
--frontend $FRONTEND \
--providers $PROVIDERS \
--yes \
--region $BACKEND_REGION 

echo "Generate code for application models"
$AMPLIFY_CLI codegen models 

if [ -d "$HOME/.aws.bak" ]; then
	echo "Restoring original AWS CLI configuration"
	mv $HOME/.aws.bak ~/.aws
fi

popd
