#!/bin/sh

## My project and environment specific values
## Replace all of these with yours 

# get the app id with : amplify env list --details

AMPLIFY_APPID=
AMPLIFY_PROJECT_NAME=
AMPLIFY_ENV=dev

# .p12 file. Can be exported from your laptop keychain 
S3_APPLE_DISTRIBUTION_CERT=s3://bucket_name/key_name 

# The password you choose when exporting the private key
APPLE_DISTRIBUTION_KEY_PASSWORD=""

# .mobileprovision file. Can be downloaded from developer.apple.com
# https://developer.apple.com/account/resources/profiles/list
S3_MOBILE_PROVISIONING_PROFILE=s3://bucket_name/key_name 

# To upload the binary to your Apple Dev Account
# Your Apple ID user name (usually a email address)
export APPLE_ID=me@me.com

# app specific password generated on appleid.apple.com 
export APPLE_SECRET=aaa-aaa-aaaa-aaaa  
