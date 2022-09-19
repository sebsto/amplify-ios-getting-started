#!/bin/zsh

# install the AWS CLI
brew install awscli

# pretty xcodebuild output 
brew install xcbeautify

#
# Verification (Actual version might be more recent)
#

brew --version
# Homebrew 3.6.1-6-g427f646
# Homebrew/homebrew-core (git revision 3a2186976bc; last commit 2022-09-12)
# Homebrew/homebrew-cask (git revision 6cdc1c28a9; last commit 2022-09-12)

aws --version
# aws-cli/2.7.31 Python/3.10.6 Darwin/21.6.0 source/arm64 prompt/off

