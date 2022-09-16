#!/bin/sh

# The region where your amplify backend is deployed
DEFAULT_REGION=eu-central-1 

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

echo "Install JQ"
brew install jq

echo "Install Amplify CLI"
# /usr/sbin/softwareupdate --install-rosetta --agree-to-license # on Apple Silicon, manually install Rosetta first
curl -sL https://aws-amplify.github.io/amplify-cli/install | bash && $SHELL

echo "Prepare AWS CLI configuration"
mkdir ~/.aws
echo "[default]\nregion=$DEFAULT_REGION\n\n" > ~/.aws/config
echo "[default]\n\n" > ~/.aws/credentials