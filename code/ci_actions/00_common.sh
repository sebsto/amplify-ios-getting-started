#!/bin/sh

arch_name="$(uname -m)"
if [ ${arch_name} = "arm64" ]; then 
    export BREW_PATH=/opt/homebrew/bin
    export AWS_CLI=$BREW_PATH/aws
else
    export BREW_PATH=/usr/local/bin
    export AWS_CLI=$BREW_PATH/aws
fi

if [ ! -z ${AWS_REGION} ]; then
    export REGION=$AWS_REGION
else
    TOKEN=$(curl -s -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
    export AWS_REGION=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/placement/region)
fi
export LANG=en_US.UTF-8

export CODE_DIR=$HOME/amplify-ios-getting-started/code # default value
if [ ! -z ${GITHUB_ACTION} ]; then # we are running from a github runner
    echo "GitHub runner detected"
    export CODE_DIR=$GITHUB_WORKSPACE/code
fi
if [ ! -z ${CI_BUILDS_DIR} ]; then # we are running from a gitlab runner
    echo "GitLab runner detected"
    export CODE_DIR=$CI_PROJECT_DIR/code
fi
if [ ! -z ${CIRCLE_WORKING_DIRECTORY} ]; then # we are running from a gitlab runner
    export "CircleCI runner detected"
    export CODE_DIR=$CIRCLE_WORKING_DIRECTORY/code
fi
if [ ! -z ${CODEBUILD_SRC_DIR} ]; then # we are running inside AWS CodeBuild
    echo "AWS CodeBuild detected"
    export CODE_DIR=$CODEBUILD_SRC_DIR/code
fi

CERTIFICATES_DIR=./code/certificates

echo "Default region: $AWS_REGION"
echo "AWS CLI       : $AWS_CLI"
echo "Code directory: $CODE_DIR"
echo "Home directory: $HOME"
echo "Certificates directory: $CERTIFICATES_DIR"