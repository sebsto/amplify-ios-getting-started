#!/bin/sh

echo "Update Brew"
brew update && brew upgrade

# pretty xcodebuild output 
echo "Install xcdeautify"
brew install xcbeautify

# Download and install Xcode :
# 1. Download it from https://developer.apple.com/download/all (requires authentication with apple id)
# 2. Store the files on your own private S3 bucket 
aws s3 cp s3://my-private-bucket/Xcode_26.0.1.xip xcode.xip
sudo xip --expand xcode.xip 
sudo mv Xcode.app /Applications

sudo installer -pkg /Applications/Xcode.app/Contents/Resources/Packages/XcodeSystemResources.pkg -target /
sudo installer -pkg /Applications/Xcode.app/Contents/Resources/Packages/CoreTypes.pkg -target /
sudo installer -pkg /Applications/Xcode.app/Contents/Resources/Packages/MobileDevice.pkg -target /
sudo installer -pkg /Applications/Xcode.app/Contents/Resources/Packages/MobileDeviceDevelopment.pkg -target /

# Download and install Xcode Command line tools:
# 1. Download it from https://developer.apple.com/download/all (requires authentication with apple id)
# 2. Store the files on your own private S3 bucket 
# aws s3 cp s3://my-private-bucket/Command_Line_Tools_for_Xcode_12.5.dmg xcode-cli.dmg
# hdiutil mount ./xcode-cli.dmg 
# sudo installer -pkg /Volumes/Command\ Line\ Developer\ Tools/Command\ Line\ Tools.pkg -target / 
# hdiutil unmount /Volumes/Command\ Line\ Developer\ Tools/

# accept the Xcode license
sudo xcodebuild -license accept 
xcode-select -p