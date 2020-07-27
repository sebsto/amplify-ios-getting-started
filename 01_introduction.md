# Introduction

## Overview

In this tutorial, you will create a simple iOS application using AWS Amplify, a set of tools and serverless services in the cloud. In the first module, you’ll build a simple iOS application. Through the remaining modules, you will initialize a local app using the Amplify Command Line Interface (Amplify CLI), add user authentication, add a GraphQL API and a database to store your data, and update your app to store images.

## What you Will Learn

This tutorial will walk you through the steps to create a simple iOS application discussed above. You will learn:

- Manage serverless cloud backend from the command line

- Authentication: Add auth to your app to enable sign-in and sign-out

- Database and Storage: Add a GraphQL API, database, and storage solution

- Share your backend between multiple projects.

## Modules

This tutorial is divided into five short modules. You must complete each module in order before moving on to the next one.

- [Create an iOS App](02_create_ios_app.md) (10 minutes): Create an iOS app and test it in the iPhone simulator.

- [Initialize a Local App](03_initialize_amplify.md) (10 minutes): Initialize a local app using AWS Amplify.

- [Add Authentication](04_add_authentication.md) (10 minutes): Add auth to your application.

- [Add a GraphQL API and Database](05_add_api_database.md) (20 minutes): Create a GraphQL API.

- [Add the Ability to Store Images](06_add_storage.md) (10 minutes): Add storage to your app.

You will be building this iOS application using the [Terminal](https://support.apple.com/en-gb/guide/terminal/welcome/mac) and Apple's [Xcode](https://developer.apple.com/xcode/) IDE

## Side Bar

| Info | Level |
| --- | --- |
| ✅ AWS Level    | Beginner |
| ✅ iOS Level    | Beginner |
| ✅ Swift Level  | Beginner |
| ⏱ Time to complete | 1h |
| 💰 Cost to complete | [Free tier](https://aws.amazon.com/free) eligible |

## Tutorial pre-requisites

To follow this tutorial, you need the following tools and resources:

- [Xcode 11.x](https://apps.apple.com/us/app/xcode/id497799835?mt=12) or more recent, available on the Apple Store.
- an [AWS Account](https://portal.aws.amazon.com/billing/signup#/start) with at least [these permissions](/amplify-policy.json).
- [NodeJS 10.x](https://nodejs.org/en/download/) or above.
- [CocoaPods 1.9.x](https://cocoapods.org/) or above.
- AWS Command Line Interface ([AWS CLI 2.0.x])(https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-install.html) or above.

You can install these tools following these instructions:

```zsh
# install brew itself
/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"

# install python3 and pip3
brew install python3

# install the AWS CLI
brew install awscli

# install Node.js & npm
brew install node

# install cocoa pods
sudo gem install cocoapods
```

Once installed, you should have at least the versions below :

```zsh
brew --version
# Homebrew 2.3.0
# Homebrew/homebrew-core (git revision 467e0; last commit 2020-06-05)
# Homebrew/homebrew-cask (git revision 8a0acb; last commit 2020-06-05)

python3 --version
# Python 3.7.3

aws --version
# aws-cli/2.0.19 Python/3.7.4 Darwin/19.5.0 botocore/2.0.0dev23

node --version
# v14.4.0

pod --version
# 1.9.3
```
