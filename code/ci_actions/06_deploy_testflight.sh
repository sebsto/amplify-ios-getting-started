#!/bin/sh
set -e 
set -o pipefail

. code/ci_actions/00_common.sh

echo "Changing to code directory at $CODE_DIR"
pushd $CODE_DIR

BUILD_PATH="./build-release"
ARCHIVE_PATH="$BUILD_PATH/getting-started.xcarchive"
EXPORT_OPTIONS_FILE="./exportOptions.plist"
SCHEME="getting started"

KEYCHAIN_PASSWORD=Passw0rd
KEYCHAIN_NAME=dev.keychain
security unlock-keychain -p $KEYCHAIN_PASSWORD $KEYCHAIN_NAME

# Apple API Key authentication
SECRET_VALUE=$(aws secretsmanager get-secret-value \
  --secret-id "ios-build-secrets" \
  --region $AWS_REGION \
  --query SecretString --output text)
APPLE_API_KEY_ID=$(echo $SECRET_VALUE | jq -r '.apple_api_key_id')
APPLE_API_KEY_B64=$(echo $SECRET_VALUE | jq -r '.apple_api_key')
APPLE_API_ISSUER=$(echo $SECRET_VALUE | jq -r '.apple_api_issuer_id')

# Create temporary API key file
API_KEY_FILE="$CERTIFICATES_DIR/AuthKey_${APPLE_API_KEY_ID}.p8"
echo $APPLE_API_KEY_B64 | base64 -d > $API_KEY_FILE

cat << EOF > $EXPORT_OPTIONS_FILE
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>destination</key>
	<string>export</string>
	<key>method</key>
	<string>app-store-connect</string>
	<key>provisioningProfiles</key>
	<dict>
		<key>com.amazonaws.amplify.mobile.getting-started</key>
		<string>amplify-ios-getting-started-dist</string>
	</dict>
	<key>signingCertificate</key>
	<string>Apple Distribution</string>
	<key>signingStyle</key>
	<string>manual</string>
	<key>stripSwiftSymbols</key>
	<true/>
	<key>teamID</key>
	<string>56U756R2L2</string>
	<key>uploadSymbols</key>
	<true/>
</dict>
</plist>
EOF

echo "Creating an Archive"
xcodebuild -exportArchive \
           -archivePath "$ARCHIVE_PATH" \
           -exportOptionsPlist "$EXPORT_OPTIONS_FILE" \
           -exportPath "$BUILD_PATH"  | $BREW_PATH/xcbeautify

echo "Verify Archive"
xcrun altool  \
            --validate-app \
            -f "$BUILD_PATH/$SCHEME.ipa" \
            -t ios \
            --apiKey $APPLE_API_KEY_ID \
            --apiIssuer $APPLE_API_ISSUER \
						-API_PRIVATE_KEYS_DIR ${CERTIFICATES_DIR}

echo "Upload to AppStore Connect"
xcrun altool  \
		--upload-app \
		-f "$BUILD_PATH/$SCHEME.ipa" \
		-t ios \
		--apiKey $APPLE_API_KEY_ID \
		--apiIssuer $APPLE_API_ISSUER \
		-API_PRIVATE_KEYS_DIR ${CERTIFICATES_DIR}

# Clean up temporary API key file
rm -f $API_KEY_FILE 

popd