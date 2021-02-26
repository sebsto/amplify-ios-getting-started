#!/bin/sh

CODE_DIR=$XCS_SOURCE_DIR/ios-getting-started/code
BUILD_NUMBER=`date +%Y%m%d%H%M%S`
plutil -replace CFBundleVersion -string $BUILD_NUMBER "$CODE_DIR/getting started/Info.plist"