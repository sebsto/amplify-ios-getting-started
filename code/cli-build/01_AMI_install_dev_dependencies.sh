#!/bin/sh

echo "Update Brew"
brew update && brew upgrade

echo "Update Ruby"
brew install ruby
echo '\n\nexport PATH="/usr/local/opt/ruby/bin:$PATH"' >> ~/.zshrc
export LDFLAGS="-L/usr/local/opt/ruby/lib"
export CPPFLAGS="-I/usr/local/opt/ruby/include"

echo "Install Fastlane"
brew install fastlane 

echo "Install cocoapods"
brew install cocoapods 

echo "Install NodeJS and JQ"
brew install node jq

echo "Install Amplify CLI"
npm install -g @aws-amplify/cli

echo "Prepare AWS CLI configuration"
mkdir ~/.aws
echo "[default]\nregion=eu-central-1\n\n" > ~/.aws/config
echo "[default]\n\n" > ~/.aws/credentials