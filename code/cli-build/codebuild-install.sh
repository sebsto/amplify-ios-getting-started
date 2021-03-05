#!/bin/sh

HOME=/Users/ec2-user
pushd $HOME 
if [ -d amplify-ios-getting-started ]; then
    rm -rf amplify-ios-getting-started
fi
git clone https://github.com/sebsto/amplify-ios-getting-started.git
CODE_DIR=$HOME/amplify-ios-getting-started/code

echo "Changing to code directory at $CODE_DIR"
cd $CODE_DIR

source ./codebuild_configuration.sh

echo "Prepare keychain"
DIST_CERT=~/apple-dist.p12
KEYCHAIN_PASSWORD=Passw0rd\!
KEYCHAIN_NAME=dev
OLD_KEYCHAIN_NAMES=login
if [ -f ~/Library/Keychains/"${KEYCHAIN_NAME}"-db ]; then
    rm ~/Library/Keychains/"${KEYCHAIN_NAME}"-db
fi
security create-keychain -p "${KEYCHAIN_PASSWORD}" "${KEYCHAIN_NAME}"
security unlock-keychain -p "${KEYCHAIN_PASSWORD}" "${KEYCHAIN_NAME}"
security list-keychains -s "${KEYCHAIN_NAME}" "${OLD_KEYCHAIN_NAMES[@]}"

curl -s -o ~/AppleWWDRCA.cer https://developer.apple.com/certificationauthority/AppleWWDRCA.cer 
security import ~/AppleWWDRCA.cer -t cert -k "${KEYCHAIN_NAME}" -T /usr/bin/codesign -T /usr/bin/xcodebuild
curl -s -o ~/AppleWWDRCAG3.cer https://www.apple.com/certificateauthority/AppleWWDRCAG3.cer
security import ~/AppleWWDRCAG3.cer -t cert -k "${KEYCHAIN_NAME}" -T /usr/bin/codesign -T /usr/bin/xcodebuild
curl -s -o ~/DevAuthCA.cer https://www.apple.com/certificateauthority/DevAuthCA.cer 
security import ~/DevAuthCA.cer -t cert -k "${KEYCHAIN_NAME}" -T /usr/bin/codesign -T /usr/bin/xcodebuild

echo $S3_APPLE_DISTRIBUTION_CERT | base64 -d > $DIST_CERT
security import "${DIST_CERT}" -P "${APPLE_DISTRIBUTION_KEY_PASSWORD}" -k "${KEYCHAIN_NAME}" -T /usr/bin/codesign -T /usr/bin/xcodebuild

security set-keychain-settings $KEYCHAIN_NAME 
security set-key-partition-list -S apple-tool:,apple: -s -k "${KEYCHAIN_PASSWORD}" "${KEYCHAIN_NAME}"

echo "Install provisioning profile"
MOBILE_PROVISIONING_PROFILE=~/project.mobileprovision
echo $S3_MOBILE_PROVISIONING_PROFILE | base64 -d > $MOBILE_PROVISIONING_PROFILE
UUID=$(security cms -D -i $MOBILE_PROVISIONING_PROFILE -k "${KEYCHAIN_NAME}" | plutil -extract UUID xml1 -o - - | xmllint --xpath "//string/text()" -)
mkdir -p "$HOME/Library/MobileDevice/Provisioning Profiles"
cp $MOBILE_PROVISIONING_PROFILE "$HOME/Library/MobileDevice/Provisioning Profiles/${UUID}.mobileprovision"
