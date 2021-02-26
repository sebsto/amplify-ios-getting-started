#!/bin/sh

source ./build_secrets.sh

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

# TODO : adjust appId and projectName

AWSCLOUDFORMATIONCONFIG="{\
\"configLevel\":\"project\",\
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

PATH=$PATH:/usr/local/bin/ # require to find node
/usr/local/bin/amplify pull \
--amplify $AMPLIFY \
--frontend $FRONTEND \
--providers $PROVIDERS \
--yes --region eu-central-1

echo "Restore generated files"
mv ./generated amplify/

# Increase Build Number
# https://rderik.com/blog/automating-build-and-testflight-upload-for-simple-ios-apps/

BUILD_NUMBER=`date +%Y%m%d%H%M%S`
plutil -replace CFBundleVersion -string $BUILD_NUMBER "./getting started/Info.plist"

# before to run this script, use the KeyChain App to 
# create a keychain, import the ios distribution
# private key and certificate 
# https://stackoverflow.com/questions/20205162/user-interaction-is-not-allowed-trying-to-sign-an-osx-app-using-codesign

echo "Prepare keychain"
DIST_CERT=~/apple-dist.p12
aws s3 cp $S3_APPLE_DISTRIBUTION_CERT $DIST_CERT
KEYCHAIN_PASSWORD=Passw0rd\!
KEYCHAIN_NAME=dev
OLD_KEYCHAIN_NAMES=login
if [ -f ~/Library/Keychains/"${KEYCHAIN_NAME}"-db ]; then
    rm ~/Library/Keychains/"${KEYCHAIN_NAME}"-db
fi
security create-keychain -p "${KEYCHAIN_PASSWORD}" "${KEYCHAIN_NAME}"
security list-keychains -s "${KEYCHAIN_NAME}" "${OLD_KEYCHAIN_NAMES[@]}"
security set-keychain-settings $KEYCHAIN_NAME 
security import "${DIST_CERT}" -P "${APPLE_DISTRIBUTION_KEY_PASSWORD}" -k "${KEYCHAIN_NAME}" -T /usr/bin/codesign -T /usr/bin/xcodebuild
security set-key-partition-list -S apple-tool:,apple: -s -k "${KEYCHAIN_PASSWORD}" "${KEYCHAIN_NAME}"

curl -o ~/AppleWWDRCA.cer https://developer.apple.com/certificationauthority/AppleWWDRCA.cer 
security import ~/AppleWWDRCA.cer -t cert -k "${KEYCHAIN_NAME}" -T /usr/bin/codesign -T /usr/bin/xcodebuild
curl -o ~/AppleWWDRCAG3.cer https://www.apple.com/certificateauthority/AppleWWDRCAG3.cer
security import ~/AppleWWDRCAG3.cer -t cert -k "${KEYCHAIN_NAME}" -T /usr/bin/codesign -T /usr/bin/xcodebuild
curl -o ~/DevAuthCA.cer https://www.apple.com/certificateauthority/DevAuthCA.cer 
security import ~/DevAuthCA.cer -t cert -k "${KEYCHAIN_NAME}" -T /usr/bin/codesign -T /usr/bin/xcodebuild

security unlock-keychain -p "${KEYCHAIN_PASSWORD}" "${KEYCHAIN_NAME}"

# security list-keychains -s ~/Library/Keychains/"${KEYCHAIN_NAME}"-db
# security default-keychain -s ~/Library/Keychains/"${KEYCHAIN_NAME}"-db


echo "Install provisioning profile"
MOBILE_PROVISIONING_PROFILE=~/project.mobileprovision
aws s3 cp $S3_MOBILE_PROVISIONING_PROFILE $MOBILE_PROVISIONING_PROFILE
UUID=$(security cms -D -i $MOBILE_PROVISIONING_PROFILE -k "${KEYCHAIN_NAME}" | plutil -extract UUID xml1 -o - - | xmllint --xpath "//string/text()" -)
mkdir -p "$HOME/Library/MobileDevice/Provisioning Profiles"
cp $MOBILE_PROVISIONING_PROFILE "$HOME/Library/MobileDevice/Provisioning Profiles/${UUID}.mobileprovision"

echo "Build, Sign and Archive"
SCHEME="getting started"
CONFIGURATION="Release"
WORKSPACE="getting started.xcworkspace"
BUILD_PATH="./build"
ARCHIVE_PATH="$BUILD_PATH/getting-started.xcarchive"
EXPORT_OPTIONS="./cli-build/ExportOptions.plist"
xcodebuild clean build archive \
           -workspace "$WORKSPACE" \
           -scheme "$SCHEME" \
           -archivePath "$ARCHIVE_PATH" \
           -configuration "$CONFIGURATION" 

xcodebuild -exportArchive \
           -archivePath "$ARCHIVE_PATH" \
           -exportOptionsPlist "$EXPORT_OPTIONS" \
           -exportPath "$BUILD_PATH"

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
