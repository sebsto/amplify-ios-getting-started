#!/bin/sh

# The region where your amplify backend is deployed
DEFAULT_REGION=eu-central-1 

echo "Update Brew"
brew update && brew upgrade

# pretty xcodebuild output 
echo "Install xcdeautify"
brew install xcbeautify

# echo "Install Fastlane"
# brew install fastlane 

echo "Install JQ"
brew install jq

echo "Install Amplify CLI"
/usr/sbin/softwareupdate --install-rosetta --agree-to-license # on Apple Silicon, manually install Rosetta first
curl -sL https://aws-amplify.github.io/amplify-cli/install | bash && $SHELL

echo "Prepare AWS CLI configuration"
mkdir ~/.aws
echo "[default]\nregion=$DEFAULT_REGION\n\n" > ~/.aws/config
echo "[default]\n\n" > ~/.aws/credentials