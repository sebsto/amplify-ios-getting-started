#!/bin/sh

arch_name="$(uname -m)"
if [ ${arch_name} = "arm64" ]; then 
    AWS_CLI=/opt/homebrew/bin/aws
else
    AWS_CLI=/usr/local/bin/aws 
fi

TOKEN=$(curl -s -H "X-aws-ec2-metadata-token-ttl-seconds: 21600" -X PUT 'http://169.254.169.254/latest/api/token')
REGION=$(curl -s -H "X-aws-ec2-metadata-token: ${TOKEN}" 'http://169.254.169.254/latest/meta-data/placement/region')
echo "${REGION}" 

HOME=/Users/ec2-user
CERTIFICATES_DIR="${HOME}/certificates";
mkdir -p "${CERTIFICATES_DIR}" 2>&1 >/dev/null

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
sudo security list-keychains -s "${SYSTEM_KEYCHAIN}"

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
SIGNING_DEV_KEY_SECRET=apple-signing-dev-certificate
MOBILE_PROVISIONING_PROFILE_DEV_SECRET=amplify-getting-started-dev-provisionning
SIGNING_DIST_KEY_SECRET=apple-signing-dist-certificate
MOBILE_PROVISIONING_PROFILE_DIST_SECRET=amplify-getting-started-dist-provisionning
MOBILE_PROVISIONING_PROFILE_TEST_SECRET=amplify-getting-started-test-provisionning

# These are base64 values, we will need to decode to a file when needed
SIGNING_DEV_KEY=$($AWS_CLI --region $REGION secretsmanager get-secret-value --secret-id $SIGNING_DEV_KEY_SECRET --query SecretBinary --output text)
MOBILE_PROVISIONING_DEV_PROFILE=$($AWS_CLI --region $REGION secretsmanager get-secret-value --secret-id $MOBILE_PROVISIONING_PROFILE_DEV_SECRET --query SecretBinary --output text)
SIGNING_DIST_KEY=$($AWS_CLI --region $REGION secretsmanager get-secret-value --secret-id $SIGNING_DIST_KEY_SECRET --query SecretBinary --output text)
MOBILE_PROVISIONING_DIST_PROFILE=$($AWS_CLI --region $REGION secretsmanager get-secret-value --secret-id $MOBILE_PROVISIONING_PROFILE_DIST_SECRET --query SecretBinary --output text)
MOBILE_PROVISIONING_TEST_PROFILE=$($AWS_CLI --region $REGION secretsmanager get-secret-value --secret-id $MOBILE_PROVISIONING_PROFILE_TEST_SECRET --query SecretBinary --output text)

echo "Import Signing private key and certificate"
DEV_KEY_FILE=$CERTIFICATES_DIR/apple_dev_key.p12
echo $SIGNING_DEV_KEY | base64 -d > $DEV_KEY_FILE
security import "${DEV_KEY_FILE}" -P "" -k "${KEYCHAIN_NAME}" "${AUTHORISATION[@]}"

DIST_KEY_FILE=$CERTIFICATES_DIR/apple_dist_key.p12
echo $SIGNING_DIST_KEY | base64 -d > $DIST_KEY_FILE
security import "${DIST_KEY_FILE}" -P "" -k "${KEYCHAIN_NAME}" "${AUTHORISATION[@]}"

# is this necessary when importing keys with -A ?
security set-key-partition-list -S apple-tool:,apple:,codesign: -s -k "${KEYCHAIN_PASSWORD}" "${KEYCHAIN_NAME}"

echo "Install development provisioning profile"
MOBILE_PROVISIONING_DEV_PROFILE_FILE=$CERTIFICATES_DIR/project-dev.mobileprovision
echo $MOBILE_PROVISIONING_DEV_PROFILE | base64 -d > $MOBILE_PROVISIONING_DEV_PROFILE_FILE
UUID=$(security cms -D -i $MOBILE_PROVISIONING_DEV_PROFILE_FILE -k "${KEYCHAIN_NAME}" | plutil -extract UUID xml1 -o - - | xmllint --xpath "//string/text()" -)
mkdir -p "$HOME/Library/MobileDevice/Provisioning Profiles"
cp $MOBILE_PROVISIONING_DEV_PROFILE_FILE "$HOME/Library/MobileDevice/Provisioning Profiles/${UUID}.mobileprovision"

echo "Install distribution provisioning profile"
MOBILE_PROVISIONING_DIST_PROFILE_FILE=$CERTIFICATES_DIR/project-dist.mobileprovision
echo $MOBILE_PROVISIONING_DIST_PROFILE | base64 -d > $MOBILE_PROVISIONING_DIST_PROFILE_FILE
UUID=$(security cms -D -i $MOBILE_PROVISIONING_DIST_PROFILE_FILE -k "${KEYCHAIN_NAME}" | plutil -extract UUID xml1 -o - - | xmllint --xpath "//string/text()" -)
cp $MOBILE_PROVISIONING_DIST_PROFILE_FILE "$HOME/Library/MobileDevice/Provisioning Profiles/${UUID}.mobileprovision"

echo "Install test provisioning profile"
MOBILE_PROVISIONING_TEST_PROFILE_FILE=$CERTIFICATES_DIR/project-test.mobileprovision
echo $MOBILE_PROVISIONING_TEST_PROFILE | base64 -d > $MOBILE_PROVISIONING_TEST_PROFILE_FILE
UUID=$(security cms -D -i $MOBILE_PROVISIONING_TEST_PROFILE_FILE -k "${KEYCHAIN_NAME}" | plutil -extract UUID xml1 -o - - | xmllint --xpath "//string/text()" -)
cp $MOBILE_PROVISIONING_TEST_PROFILE_FILE "$HOME/Library/MobileDevice/Provisioning Profiles/${UUID}.mobileprovision"
