#!/bin/sh

# Thanks to 
# https://medium.com/appssemble/a-guide-to-writing-your-own-ios-ci-cd-integration-script-186be1b99575

HOME=/Users/ec2-user
pushd $HOME 
rm -rf amplify-ios-getting-started
git clone https://github.com/sebsto/amplify-ios-getting-started.git
CODE_DIR=$HOME/amplify-ios-getting-started/code

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

# Increase Build Number
# https://rderik.com/blog/automating-build-and-testflight-upload-for-simple-ios-apps/

BUILD_NUMBER=`date +%Y%m%d%H%M%S`
plutil -replace CFBundleVersion -string $BUILD_NUMBER "./getting started/Info.plist"

# before to run this script, use the KeyChain App to 
# create a keychain, import the ios distribution
# private key and certificate 
echo "Prepare keychain"
KEYCHAIN_PASSWORD=Passw0rd!
KEYCHAIN_NAME=ios-distribution
KEYCHAIN_PATH=$HOME/Library/Keychains/$KEYCHAIN_NAME.keychain-db
OLD_KEYCHAIN_PATH=$HOME/Library/Keychains/login.keychain-db 

security list-keychains -s $KEYCHAIN_PATH
security default-keychain -s $KEYCHAIN_PATH
security unlock-keychain -p $KEYCHAIN_PASSWORD $KEYCHAIN_PATH

PROVISIONING_PROFILE_PATH
SCHEME="getting started"
CONFIGURATION="Release"
WORKSPACE="getting started.xcworkspace"
BUILD_PATH="./build"
ARCHIVE_PATH="$BUILD_PATH/getting-started.xcarchive"
EXPORT_OPTIONS="./cli-build/ExportOptions.plist"

echo "Build, Sign and Archive"
xcodebuild clean build archive \
           -workspace "$WORKSPACE" \
           -scheme "$SCHEME" \
           -archivePath "$ARCHIVE_PATH" \
           -configuration "$CONFIGURATION" 

xcodebuild -exportArchive \
           -archivePath "$ARCHIVE_PATH" \
           -exportOptionsPlist "$EXPORT_OPTIONS" \
           -exportPath "$BUILD_PATH"

# Restore login keychain as default
echo "Restore keychain" 
security list-keychains -d user -s "$OLD_KEYCHAIN_PATH" "$KEYCHAIN_PATH"
security list-keychains -s "$OLD_KEYCHAIN_PATH"
security default-keychain -s "$OLD_KEYCHAIN_PATH"

export APPLE_ID=sebsto@me.com
export APPLE_SECRET=vgru-usai-krtq-vjer  # app specific password generated on appleid.apple.com 

echo "Verify Archive"
xcrun altool  \
            --validate-app \
            -f "$(pwd)/build/$SCHEME.ipa" \
            -t ios \
            -u $APPLE_ID \
            -p @env:APPLE_SECRET

echo "Upload Archive to iTunesConnect"
xcrun altool  \
            --upload-app \
            -f "$(pwd)/build/$SCHEME.ipa" \
            -t ios \
            -u $APPLE_ID \
            -p @env:APPLE_SECRET

echo "Done"
