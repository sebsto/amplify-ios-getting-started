# Introduction

Now that you have a full project running, let's explore two options frequently used : the ability to share your project's backend with another app, and the deletion of backend resources.

## What You Will Learn

- Sharing an Amplify backend configuration accross projects
- Delete a cloud backend using Amplify CLI 

## Key Concepts

Shared Backend - it is common to have multiple front end applications sharing a common backend.  For example, you might have a tvOS, Android, iOS, and web frtont end all sharing the same API, database, storage, and user authentication.

# Implementation

## Share your Backend Between Multiple Projects

Amplify makes it easy to share a single backend between multiple front end application.

In a terminal, navigate to your other project directory and **execute the following command**:

```zsh
mkdir other-project
cd other-project

amplify pull
```

- *? Do you want to use an AWS profile?* accept the default **Yes** and press **enter**
- *? Please choose the profile you want to use* select the profile you want to use and press **enter**
- *? Which app are you working on?* select the backend you want to share and press **enter**
- *? Choose your default editor:* select you prefered text editor and press **enter**
- *? Choose the type of app that you're building* select the operating system for your new project and press **enter**
- *? Do you plan on modifying this backend?* most of the time, select **No** and press **enter**.  All backend modifications can be done from the original iOS project.

After a few seconds, you will see the following message:

```text
Added backend environment config object to your project.
Run 'amplify pull' to sync upstream changes.
```

You can see the two configurations files that have been pulled out.  When you answer 'Yes' to the question 'Do you plan on modifying this backend?', you also see a `amplify` directory.

```zsh
➜  other-project git:(master) ✗ ls -al
total 24
drwxr-xr-x   5 stormacq  admin   160 Jul 10 10:28 .
drwxr-xr-x  19 stormacq  admin   608 Jul 10 10:27 ..
-rw-r--r--   1 stormacq  admin   315 Jul 10 10:28 .gitignore
-rw-r--r--   1 stormacq  admin  3421 Jul 10 10:28 amplifyconfiguration.json
-rw-r--r--   1 stormacq  admin  1897 Jul 10 10:28 awsconfiguration.json
```

## Delete your Backend

When creating a backend for a test or a prototype, or just for learning purposes, just like when you follow this tutorial, you want to delete the cloud resources that have been created.  

Although the usage of this resources in the context of this tutorial fall under the [free tier](https://aws.amazon.com/free), it is a best practice to clean up unused resources in the cloud.

To clean your amplify project, in a terminal, execute the following command:

```zsh
amplify delete
```

After a while, you will see the below message confirming all cloud resources have been deleted.

```text
✔ Project deleted in the cloud
Project deleted locally.
```

Thank you for having followed this tutorial until the end. Please le us know your feedback by opening an issue or a pull request on our [GitHub repository](https://github.com/sebsto/amplify-ios-getting-started).