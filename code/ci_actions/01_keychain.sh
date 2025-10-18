#!/bin/sh

. code/ci_actions/00_common.sh

mkdir -p $CERTIFICATES_DIR 2>&1 >/dev/null
echo "Certificates directory: $CERTIFICATES_DIR"

echo "Cleaning Provisioning Profiles"
rm -rf "$HOME/Library/MobileDevice/Provisioning Profiles"

echo "Prepare keychain"
KEYCHAIN_PASSWORD=Passw0rd
KEYCHAIN_NAME=dev.keychain
SYSTEM_KEYCHAIN=/Library/Keychains/System.keychain
AUTHORISATION=(-T /usr/bin/security -T /usr/bin/codesign -T /usr/bin/xcodebuild)

echo "Re-Creating System Keychain"
sudo security delete-keychain "${SYSTEM_KEYCHAIN}" 
sudo security create-keychain -p "${KEYCHAIN_PASSWORD}" "${SYSTEM_KEYCHAIN}"
security list-keychains -s "${SYSTEM_KEYCHAIN}"

if [ -f $HOME/Library/Keychains/"${KEYCHAIN_NAME}"-db ]; then
    echo "Deleting old ${KEYCHAIN_NAME} keychain"
    security delete-keychain "${KEYCHAIN_NAME}"
fi

echo "Creating keychain"
security create-keychain -p "${KEYCHAIN_PASSWORD}" "${KEYCHAIN_NAME}"

echo "Adding the build keychain to the search list"
EXISTING_KEYCHAINS=( $( security list-keychains | sed -e 's/ *//' | tr '\n' ' ' | tr -d '"') )
sudo security list-keychains -s "${KEYCHAIN_NAME}" "${EXISTING_KEYCHAINS[@]}"
echo "New keychain search list :"
security list-keychain 

# at this point the keychain is unlocked, the below line is not needed
security unlock-keychain -p "${KEYCHAIN_PASSWORD}" "${KEYCHAIN_NAME}"

echo "Configure keychain : remove lock timeout"
security set-keychain-settings "${KEYCHAIN_NAME}"

if [ ! -f $CERTIFICATES_DIR/AppleWWDRCAG3.cer ]; then
    echo "Downloadind Apple Worlwide Developer Relation GA3 certificate"
    curl -s -o $CERTIFICATES_DIR/AppleWWDRCAG3.cer https://www.apple.com/certificateauthority/AppleWWDRCAG3.cer
fi
sudo security find-certificate -c "Apple Worldwide Developer Relations Certification Authority"  /Library/Keychains/System.keychain 2>/dev/null
if [ $? -ne 0 ]; then
    echo "Installing Apple Worlwide Developer Relation GA3 certificate into System keychain"
    sudo security import $CERTIFICATES_DIR/AppleWWDRCAG3.cer -t cert -k "${SYSTEM_KEYCHAIN}" "${AUTHORISATION[@]}"
fi

echo "Retrieve application dev and dist keys from AWS Secret Manager"
# Get the secret and extract files
SECRET_VALUE=$(aws secretsmanager get-secret-value \
  --secret-id "ios-build-secrets" \
  --region $AWS_REGION \
  --query SecretString --output text)

# Extract each file
echo "$SECRET_VALUE" | jq -r '.apple_dev_key_p12' | base64 -d > ${CERTIFICATES_DIR}/apple_dev_key.p12
echo "$SECRET_VALUE" | jq -r '.apple_dist_key_p12' | base64 -d > ${CERTIFICATES_DIR}/apple_dist_key.p12
echo "$SECRET_VALUE" | jq -r '.dev_mobileprovision' | base64 -d > ${CERTIFICATES_DIR}/dev.mobileprovision
echo "$SECRET_VALUE" | jq -r '.dist_mobileprovision' | base64 -d > ${CERTIFICATES_DIR}/dist.mobileprovision
echo "$SECRET_VALUE" | jq -r '.uitests_mobileprovision' | base64 -d > ${CERTIFICATES_DIR}/uitests.mobileprovision

echo "Import Signing private key and certificate"
DEV_KEY_FILE=$CERTIFICATES_DIR/apple_dev_key.p12
security import "${DEV_KEY_FILE}" -P "" -k "${KEYCHAIN_NAME}" "${AUTHORISATION[@]}"

DIST_KEY_FILE=$CERTIFICATES_DIR/apple_dist_key.p12
security import "${DIST_KEY_FILE}" -P "" -k "${KEYCHAIN_NAME}" "${AUTHORISATION[@]}"

# is this necessary when importing keys with -A ?
security set-key-partition-list -S apple-tool:,apple:,codesign: -s -k "${KEYCHAIN_PASSWORD}" "${KEYCHAIN_NAME}"

echo "Install development provisioning profile"
MOBILE_PROVISIONING_DEV_PROFILE_FILE=$CERTIFICATES_DIR/dev.mobileprovision
UUID=$(security cms -D -i $MOBILE_PROVISIONING_DEV_PROFILE_FILE -k "${KEYCHAIN_NAME}" | plutil -extract UUID xml1 -o - - | xmllint --xpath "//string/text()" -)
mkdir -p "$HOME/Library/MobileDevice/Provisioning Profiles"
cp $MOBILE_PROVISIONING_DEV_PROFILE_FILE "$HOME/Library/MobileDevice/Provisioning Profiles/${UUID}.mobileprovision"

echo "Install distribution provisioning profile"
MOBILE_PROVISIONING_DIST_PROFILE_FILE=$CERTIFICATES_DIR/dist.mobileprovision
UUID=$(security cms -D -i $MOBILE_PROVISIONING_DIST_PROFILE_FILE -k "${KEYCHAIN_NAME}" | plutil -extract UUID xml1 -o - - | xmllint --xpath "//string/text()" -)
cp $MOBILE_PROVISIONING_DIST_PROFILE_FILE "$HOME/Library/MobileDevice/Provisioning Profiles/${UUID}.mobileprovision"

echo "Install test provisioning profile"
MOBILE_PROVISIONING_TEST_PROFILE_FILE=$CERTIFICATES_DIR/uitests.mobileprovision
UUID=$(security cms -D -i $MOBILE_PROVISIONING_TEST_PROFILE_FILE -k "${KEYCHAIN_NAME}" | plutil -extract UUID xml1 -o - - | xmllint --xpath "//string/text()" -)
cp $MOBILE_PROVISIONING_TEST_PROFILE_FILE "$HOME/Library/MobileDevice/Provisioning Profiles/${UUID}.mobileprovision"
