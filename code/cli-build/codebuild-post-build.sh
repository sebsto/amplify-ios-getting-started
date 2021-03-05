#!/bin/sh

source ./codebuild-configuration.sh

echo "Creating an Archive"
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