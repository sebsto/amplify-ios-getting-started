# Introduction

Now that you have a full project running, let's explore two options frequently used with Amplify Gen2: the ability to share your project's backend with another app, and the deletion of backend resources.

## What You Will Learn

- Sharing an Amplify Gen2 backend configuration across projects
- Delete a cloud backend using Amplify Gen2 commands 

## Key Concepts

Shared Backend - it is common to have multiple front end applications sharing a common backend in one single AWS account. For example, you might have a tvOS, Android, iOS, and web frontends, all sharing the same API, database, storage, and user authentication. With Amplify Gen2, this is achieved by sharing the `amplify_outputs.json` configuration file.

# Implementation

## Share your Backend Between Multiple Projects

Amplify Gen2 makes it easy to share a single backend between multiple front end applications by sharing the configuration file.

### Option 1: Generate Outputs for Another Project

If you have an existing Amplify Gen2 backend deployed, you can generate the configuration for another project:

```zsh
# In your original project directory
npx ampx generate outputs --app-id <your-app-id> --branch main --out-dir ../other-project --format json
```

### Option 2: Copy Configuration File

Simply copy the `amplify_outputs.json` file to your other project:

```zsh
mkdir other-project
cp amplify_outputs.json other-project/
```


## Delete your Backend

When creating a backend for a test or a prototype, or just for learning purposes, you want to delete the cloud resources that have been created.

Although the usage of these resources in the context of this tutorial fall under the [free tier](https://aws.amazon.com/free), it is a best practice to clean up unused resources in the cloud.

### Option 1: Delete Sandbox Resources

If you used the sandbox for development, simply stop the sandbox and delete the resources:

```zsh
# Stop the sandbox (Ctrl+C if running)
# Then delete the sandbox resources
npx ampx sandbox delete
```

### Option 2: Delete via AWS Console

You can also delete resources through the AWS Console:

1. Go to [AWS Amplify Console](https://console.aws.amazon.com/amplify/)
2. Select your app
3. Go to **Actions** > **Delete app**
4. Confirm deletion

### Option 3: Delete CloudFormation Stacks

For more control, delete the CloudFormation stacks directly:

```zsh
# List Amplify-related stacks
aws cloudformation list-stacks --query 'StackSummaries[?contains(StackName, `amplify`) && StackStatus != `DELETE_COMPLETE`].[StackName,StackStatus]' --output table

# Delete specific stacks (replace with your actual stack names)
aws cloudformation delete-stack --stack-name amplify-<your-app-name>-<branch>-<random-id>
```

After deletion, all cloud resources including:
- Cognito User Pool
- AppSync GraphQL API
- DynamoDB tables
- S3 buckets
- IAM roles and policies

will be permanently removed.

## Congratulations! 🎉

You have successfully built a full-stack iOS application using:

- **Amplify Gen2** with TypeScript backend definitions
- **Swift 6** and **iOS 18** with modern SwiftUI patterns
- **Authentication** with SwiftUI Authenticator
- **GraphQL API** with real-time capabilities
- **File Storage** with S3 integration
- **Modern Swift Concurrency** (async/await)

Thank you for following this tutorial! Please let us know your feedback by opening an issue or a pull request on our [GitHub repository](https://github.com/sebsto/amplify-ios-getting-started).

[Back](/01_introduction.md) to the start.