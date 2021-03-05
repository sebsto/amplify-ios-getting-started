#!/bin/sh

## My project and environment specific values
## Replace all of these with yours 

REGION=us-east-2

# My secret ARNs, you get them from import_secrets.sh
AMPLIFY_APPID_SECRET=amplify-app-id
AMPLIFY_PROJECT_NAME_SECRET=amplify-project-name
AMPLIFY_ENV_SECRET=amplify-environment
APPLE_ID_SECRET=apple-id
APPLE_SECRET_SECRET=apple-secret
S3_APPLE_DISTRIBUTION_CERT_SECRET=apple-dist-certificate
S3_MOBILE_PROVISIONING_PROFILE_SECRET=amplify-getting-started-provisionning

# 3. get the secrets at build
AMPLIFY_APPID=$(aws --region $REGION secretsmanager get-secret-value --secret-id $AMPLIFY_APPID_SECRET --query SecretString --output text)
AMPLIFY_PROJECT_NAME=$(aws --region $REGION secretsmanager get-secret-value --secret-id $AMPLIFY_PROJECT_NAME_SECRET --query SecretString --output text)
AMPLIFY_ENV=$(aws --region $REGION secretsmanager get-secret-value --secret-id $AMPLIFY_ENV_SECRET --query SecretString --output text)  

APPLE_ID=$(aws --region $REGION secretsmanager get-secret-value --secret-id $APPLE_ID_SECRET --query SecretString --output text)
APPLE_SECRET=$(aws --region $REGION secretsmanager get-secret-value --secret-id $APPLE_SECRET_SECRET --query SecretString --output text)

# These are base64 values, we will need to decode to a file when needed
S3_APPLE_DISTRIBUTION_CERT=$(aws --region $REGION secretsmanager get-secret-value --secret-id $S3_APPLE_DISTRIBUTION_CERT_SECRET --query SecretBinary --output text)
S3_MOBILE_PROVISIONING_PROFILE=$(aws --region $REGION secretsmanager get-secret-value --secret-id $S3_MOBILE_PROVISIONING_PROFILE_SECRET --query SecretBinary --output text)

SCHEME="getting started"
CONFIGURATION="Release"
WORKSPACE="getting started.xcworkspace"
BUILD_PATH="./build"
ARCHIVE_PATH="$BUILD_PATH/getting-started.xcarchive"
EXPORT_OPTIONS="./cli-build/ExportOptions.plist"