#!/bin/sh
set -e 
set -o pipefail

HOME=/Users/ec2-user

arch_name="$(uname -m)"
if [ ${arch_name} = "arm64" ]; then 
    BREW_PATH=/opt/homebrew/bin
    AWS_CLI=$BREW_PATH/aws
else
    BREW_PATH=/usr/local/bin 
    AWS_CLI=$BREW_PATH/aws
fi

REGION=$(curl -s 169.254.169.254/latest/meta-data/placement/region/)
export LANG=en_US.UTF-8

if [ ! -z ${GITHUB_ACTION} ]; then # we are running from a github runner
    CODE_DIR=$GITHUB_WORKSPACE/code
fi
if [ ! -z ${CI_BUILDS_DIR} ]; then # we are running from a gitlab runner
    CODE_DIR=$CI_PROJECT_DIR/code
fi
if [ -z ${CODE_DIR} ]; then
    echo Neither GitLab nor GitHub detected. Where are we running ?
    exit -1 
fi

echo "Changing to code directory at $CODE_DIR"
pushd $CODE_DIR

BUILD_PATH="./build"
ARCHIVE_PATH="$BUILD_PATH/getting-started.xcarchive"
EXPORT_OPTIONS_FILE="./exportOptions.plist"
SCHEME="getting started"

KEYCHAIN_PASSWORD=Passw0rd
KEYCHAIN_NAME=dev.keychain
security unlock-keychain -p $KEYCHAIN_PASSWORD $KEYCHAIN_NAME

APPLE_ID_SECRET=apple-id
APPLE_SECRET_SECRET=apple-secret
APPLE_ID=$($AWS_CLI --region $REGION secretsmanager get-secret-value --secret-id $APPLE_ID_SECRET --query SecretString --output text)
export APPLE_SECRET=$($AWS_CLI --region $REGION secretsmanager get-secret-value --secret-id $APPLE_SECRET_SECRET --query SecretString --output text)

cat << EOF > $EXPORT_OPTIONS_FILE
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>destination</key>
	<string>export</string>
	<key>method</key>
	<string>app-store</string>
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
            -u $APPLE_ID \
            -p @env:APPLE_SECRET 

echo "Upload to AppStore Connect"
xcrun altool  \
		--upload-app \
		-f "$BUILD_PATH/$SCHEME.ipa" \
		-t ios \
		-u $APPLE_ID \
		-p @env:APPLE_SECRET 

popd