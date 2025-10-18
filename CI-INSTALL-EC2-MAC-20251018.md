## Prepare the Build environment

This is a one time setup on new EC2 Mac instances.

### Update common dev tools

```
brew update 
brew upgrade 
brew install xcbeautify
```

### Install Xcode 

I use [xcodeinstall](https://github.com/sebsto/xcodeinstall) to install Xcode from SSH.

On your laptop 
```
# one off, install xcodeinstall and store your Apple developer portal credentials on Secrets Manager
brew tap sebsto/macos
brew install xcodeinstall

# Store your Apple credentials on Secrets Manager to not enter them each time
# This is optional
xcodeinstall storesecrets -s us-east-1

# `authenticate` creates a session that will stay valid for several hours
# Provide your Apple ID credentials if you did not store them in Secrets Manager
# This command will trigger MFA when configured
# Repeat this command each time the session expired
xcodeinstall authenticate -s us-east-1
```

On the EC2 Mac machine 
```
brew tap sebsto/macos
brew install xcodeinstall

# To see files available (-x to list a specific Xcode major version)
xcodeinstall list -f -x 26 -s us-east-1

# When you know which file to download (skip --name for interactive UI)
xcodeinstall download -s us-east-1 --name "Xcode 26.0.1 Universal.xip"

# Install Xcode (skip --name for interactive UI)
# Note 18 Oct 2025 : 
# After Xcode installation, the package installation hangs. You can safely CTRL-C
xcodeinstall install --name "Xcode 26.0.1 Universal.xip"

# Not mandatory but it helps 
sudo mv /Applications/Xcode.app /Applications/Xcode-26.0.1.app
sudo ln -s /Applications/Xcode-26.0.1.app /Applications/Xcode.app  

# Accept the Xcode license
sudo xcodebuild -license accept 

xcode-select -p
# should output: /Applications/Xcode.app/Contents/Developer

# Install iOS runtime for testing the app
xcodebuild -downloadPlatform iOS
```

### Install the GitHub Actions Runner 



## IAM Permission for your CICD host 

(Remove the Amplify related permissions when not using AWS Amplify)

```
{
	"Version": "2012-10-17",
	"Statement": [
		{
			"Sid": "AmplifyAccess",
			"Effect": "Allow",
			"Action": [
				"cloudformation:List*",
				"cloudformation:Describe*",
				"cloudformation:Get*",
				"cloudformation:Validate*",
				"cloudformation:Detect*",
				"cognito-idp:ListUserPools",
				"cognito-idp:ListIdentityProviders",
				"cognito-idp:DescribeIdentityProvider",
				"amplify:List*",
				"amplify:Get*"
			],
			"Resource": "*"
		},
		{
			"Sid": "AmplifyS3Access",
			"Effect": "Allow",
			"Action": [
				"s3:List*",
				"s3:Get*"
			],
			"Resource": [
				"arn:aws:s3:::amplify-*"
			]
		},
		{
			"Sid": "SecretsManagerAccess",
			"Effect": "Allow",
			"Action": "secretsmanager:GetSecretValue",
			"Resource": [
				"arn:aws:secretsmanager:*:<YOUR ACCOUNT ID>:secret:ios-build-secrets*",
			]
		},
		{
			"Sid": "xcodeinstall",
			"Effect": "Allow",
			"Action": [
				"secretsmanager:CreateSecret",
				"secretsmanager:GetSecretValue",
				"secretsmanager:PutSecretValue"
			],
			"Resource": "arn:aws:secretsmanager:*:<YOUR ACCOUNT ID>:secret:xcodeinstall-*"
		},
		{
			"Sid": "DeviceFarmAccess",
			"Effect": "Allow",
			"Action": [
				"devicefarm:CreateUpload",
				"devicefarm:GetUpload",
				"devicefarm:ListUploads",
				"devicefarm:ListDevicePools",
				"devicefarm:ScheduleRun",
				"devicefarm:GetRun"
			],
			"Resource": "*"
		}
	]
}
```
### Amplify-based app - manual validation

```
brew install node

git clone https://github.com/sebsto/amplify-ios-getting-started
cd amplify-ios-getting-started
npm install amplify@latest
npm add --save-dev @aws-amplify/backend@latest @aws-amplify/backend-cli@latest typescript

# Create the backend environment - one off
export CI=true
export GITHUB_ACTIONS=true
export GITHUB_REF=refs/heads/main
export GITHUB_SHA=$(git rev-parse HEAD)

export AMPLIFY_APP_ID=d199v9208momso

npx ampx pipeline-deploy     \
  --branch main              \
  --app-id ${AMPLIFY_APP_ID} \
  --outputs-out-dir .        \
  --outputs-format json

# In the CI - at each execution
# Replaces the developer-provided `amplify-output.json` with the one containing the backend configuration
TOKEN=$(curl -s -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
export AWS_REGION=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/placement/region)

npx ampx generate outputs.   \
  --app-id ${AMPLIFY_APP_ID} \
  --branch main              \
  --out-dir .                \
  --format json
	```