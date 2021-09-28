#!/bin/sh

# First resize the file system to enjoy the full space offered by our EBS volume
PDISK=$(diskutil list physical external | head -n1 | cut -d" " -f1)
APFSCONT=$(diskutil list physical external | grep "Apple_APFS" | tr -s " " | cut -d" " -f8)
yes | sudo diskutil repairDisk $PDISK
sudo diskutil apfs resizeContainer $APFSCONT 0

# Download and install Xcode :
# 1. Download it from https://developer.apple.com/download/all (requires authentication with apple id)
# 2. Store the files on your own private S3 bucket 
aws s3 cp s3://my-private-bucket/Xcode_12.5.xip xcode.xip
xip --expand xcode.xip 
sudo mv Xcode.app /Applications

sudo installer -pkg /Applications/Xcode.app/Contents/Resources/Packages/XcodeSystemResources.pkg -target /
sudo installer -pkg /Applications/Xcode.app/Contents/Resources/Packages/CoreTypes.pkg -target /
sudo installer -pkg /Applications/Xcode.app/Contents/Resources/Packages/MobileDevice.pkg -target /
sudo installer -pkg /Applications/Xcode.app/Contents/Resources/Packages/MobileDeviceDevelopment.pkg -target /

# Download and install Xcode :
# 1. Download it from https://developer.apple.com/download/all (requires authentication with apple id)
# 2. Store the files on your own private S3 bucket 
aws s3 cp s3://my-private-bucket/Command_Line_Tools_for_Xcode_12.5.dmg xcode-cli.dmg
hdiutil mount ./xcode-cli.dmg 
sudo installer -pkg /Volumes/Command\ Line\ Developer\ Tools/Command\ Line\ Tools.pkg -target / 
hdiutil unmount /Volumes/Command\ Line\ Developer\ Tools/

# accept the Xcode license
sudo xcodebuild -license accept 
xcode-select -p