#!/bin/bash

WORKSPACE="getting started.xcworkspace"
SCHEME="getting started"
PHONE_MODEL="iPhone 13"
IOS_VERSION="15.0"

xcodebuild test \
    -workspace $WORKSPACE \
    -scheme $SCHEME        \
    -destination platform="iOS Simulator",name="${PHONE_MODEL}",OS=${IOS_VERSION} >> /Users/ec2-user/log/unit_tests.log 2>&1