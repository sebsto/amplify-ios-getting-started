#!/bin/sh

/usr/bin/xcodebuild \
    -exportArchive \
    -archivePath "${XCS_ARCHIVE}" \
    -exportPath "${XCS_DERIVED_DATA_DIR}" \
    -exportOptionsPlist "${XCS_SOURCE_DIR}/ios-getting-started/code/cli-build/ExportOptions.plist"

export APPLE_ID=sebsto@me.com
export APPLE_SECRET=vgru-usai-krtq-vjer  # app specific password generated on appleid.apple.com 

/usr/bin/xcrun altool \
    --upload-app \
    --type ios \
    --file "${XCS_DERIVED_DATA_DIR}/getting started.ipa" \
    -u $APPLE_ID \
    -p @env:APPLE_SECRET 

