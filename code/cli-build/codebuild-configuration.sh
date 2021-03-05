#!/bin/sh
set -e # force an exit if one command fails

## My project and environment specific values
## Replace all of these with yours 

AWS_CLI=/usr/local/bin/aws
REGION=$(curl -s 169.254.169.254/latest/meta-data/placement/region/)

# My secret ARNs, you get them from import_secrets.sh
AMPLIFY_APPID_SECRET=amplify-app-id
AMPLIFY_PROJECT_NAME_SECRET=amplify-project-name
AMPLIFY_ENV_SECRET=amplify-environment
APPLE_ID_SECRET=apple-id
APPLE_SECRET_SECRET=apple-secret
S3_APPLE_DISTRIBUTION_CERT_SECRET=apple-dist-certificate
S3_MOBILE_PROVISIONING_PROFILE_SECRET=amplify-getting-started-provisionning

# 3. get the secrets at build
AMPLIFY_APPID=$($AWS_CLI --region $REGION secretsmanager get-secret-value --secret-id $AMPLIFY_APPID_SECRET --query SecretString --output text)
AMPLIFY_PROJECT_NAME=$($AWS_CLI --region $REGION secretsmanager get-secret-value --secret-id $AMPLIFY_PROJECT_NAME_SECRET --query SecretString --output text)
AMPLIFY_ENV=$($AWS_CLI --region $REGION secretsmanager get-secret-value --secret-id $AMPLIFY_ENV_SECRET --query SecretString --output text)  

export APPLE_ID=$($AWS_CLI --region $REGION secretsmanager get-secret-value --secret-id $APPLE_ID_SECRET --query SecretString --output text)
export APPLE_SECRET=$($AWS_CLI --region $REGION secretsmanager get-secret-value --secret-id $APPLE_SECRET_SECRET --query SecretString --output text)

# These are base64 values, we will need to decode to a file when needed
S3_APPLE_DISTRIBUTION_CERT=$($AWS_CLI --region $REGION secretsmanager get-secret-value --secret-id $S3_APPLE_DISTRIBUTION_CERT_SECRET --query SecretBinary --output text)
S3_MOBILE_PROVISIONING_PROFILE=$($AWS_CLI --region $REGION secretsmanager get-secret-value --secret-id $S3_MOBILE_PROVISIONING_PROFILE_SECRET --query SecretBinary --output text)

SCHEME="getting started"
CONFIGURATION="Release"
WORKSPACE="getting started.xcworkspace"
BUILD_PATH="./build"
ARCHIVE_PATH="$BUILD_PATH/getting-started.xcarchive"
EXPORT_OPTIONS="./cli-build/ExportOptions.plist"