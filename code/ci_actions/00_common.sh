#!/bin/sh

arch_name="$(uname -m)"
if [ ${arch_name} = "arm64" ]; then 
    export BREW_PATH=/opt/homebrew/bin
    export AWS_CLI=$BREW_PATH/aws
else
    export BREW_PATH=/usr/local/bin
    export AWS_CLI=$BREW_PATH/aws
fi

export REGION=$(curl -s 169.254.169.254/latest/meta-data/placement/region/)
export LANG=en_US.UTF-8

export HOME=/Users/ec2-user
export CODE_DIR=$HOME/amplify-ios-getting-started/code # default value
if [ ! -z ${GITHUB_ACTION} ]; then # we are running from a github runner
    export CODE_DIR=$GITHUB_WORKSPACE/code
fi
if [ ! -z ${CI_BUILDS_DIR} ]; then # we are running from a gitlab runner
    export CODE_DIR=$CI_PROJECT_DIR/code
fi

echo "Default region: $REGION"
echo "AWS CLI       : $AWS_CLI"
echo "Code directory: $CODE_DIR"
echo "Home directory: $HOME"