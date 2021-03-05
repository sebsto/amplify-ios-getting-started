#!/bin/sh

CODE_DIR=$HOME/amplify-ios-getting-started/code
echo "Changing to code directory at $CODE_DIR"
cd $CODE_DIR
source $CODE_DIR/cli-build/codebuild-configuration.sh

echo "Creating an Archive"
xcodebuild -exportArchive \
           -archivePath "$ARCHIVE_PATH" \
           -exportOptionsPlist "$EXPORT_OPTIONS" \
           -exportPath "$BUILD_PATH" > $HOME/log/export.log

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