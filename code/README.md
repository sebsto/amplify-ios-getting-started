![Build status](https://codebuild.us-east-2.amazonaws.com/badges?uuid=eyJlbmNyeXB0ZWREYXRhIjoiVFpRMy9XOXVubXFyR1dRTHhXRGdEZjBYU3Q2R2lsQ2R0RjRpaDRGcllQYjdaUmQ2V01kVWZ2OENvZGVJckRIMkdVc1YrK0pTQjVQa21mN3hQdW5iQUxvPSIsIml2UGFyYW1ldGVyU3BlYyI6IlM1dk41dDhNVDZ1dWNXN0UiLCJtYXRlcmlhbFNldFNlcmlhbCI6MX0%3D&branch=main)

# Instructions to build on Amazon EC2

The below are step by step instructions to build this project on macOS.  It describe how to start an Amazon EC2 mac1 instance and how to use the command line to install your development environment and to build the project.  If you are using your own Mac, you can skip the Amazon EC2 section.

## Prepare a mac1 EC2 instance with Xcode (one time setup)

1. Get an mac1 instance ([doc](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-mac-instances.html)).

### Tips
- Remember, you need to allocate a dedicated host.  Minimum billing period is 24h. 

- Choose an EBS volume large enough, Xcode and development tools need space. I use a 500Gb gp3 volume.

- Create a Security Group with at least SSH (TCP 22). If you plan to use Xcode Server, add the following:
   - TCP 443 (HTTPS)
   - TCP 20300 (Xcode Server)
   - TCP 20343 - 20346 (Xcode Server)   

  It is always a good idea to restrict the source IP to your laptop / internet box (to find out your current IP address, use `curl ifconfig.me`)

- Do not forget to attach your SSH public key

Now that you have access to a macOS EC2 Instance, let's install Xcode.

2. Connect to your mac1 EC2 instance using SSH

   `ssh -i /path/to/my/private-ssh-key.pem ec2-user@<mac1_instance_IP_address>`

3. Install Xcode

   ```bash
   echo "export LANG=en_US.UTF-8\n" >> ~/.zshrc 
   echo "export LANGUAGE=en_US.UTF-8\n" >> ~/.zshrc 
   echo "export LC_ALL=en_US.UTF-8\n" >> ~/.zshrc 

   # First resize the file system to enjoy the full space offered by our EBS volume
   PDISK=$(diskutil list physical external | head -n1 | cut -d" " -f1)
   APFSCONT=$(diskutil list physical external | grep "Apple_APFS" | tr -s " " | cut -d" " -f8)
   yes | sudo diskutil repairDisk $PDISK
   sudo diskutil apfs resizeContainer $APFSCONT 0

   # Download and install Xcode :
   # 1. Download it from https://developer.apple.com/download/all (requires authentication with apple id)
   # 2. Store the files on your own private S3 bucket 
   aws s3 cp s3://my-private-bucket/Xcode_12.5.xip xcode.xip
   xip --expand xcode.xip 
   sudo mv Xcode.app /Applications

   sudo installer -pkg /Applications/Xcode.app/Contents/Resources/Packages/XcodeSystemResources.pkg -target /
   sudo installer -pkg /Applications/Xcode.app/Contents/Resources/Packages/CoreTypes.pkg -target /
   sudo installer -pkg /Applications/Xcode.app/Contents/Resources/Packages/MobileDevice.pkg -target /
   sudo installer -pkg /Applications/Xcode.app/Contents/Resources/Packages/MobileDeviceDevelopment.pkg -target /

   # Download and install Xcode :
   # 1. Download it from https://developer.apple.com/download/all (requires authentication with apple id)
   # 2. Store the files on your own private S3 bucket 
   aws s3 cp s3://my-private-bucket/Command_Line_Tools_for_Xcode_12.5.dmg xcode-cli.dmg
   hdiutil mount ./xcode-cli.dmg 
   sudo installer -pkg /Volumes/Command\ Line\ Developer\ Tools/Command\ Line\ Tools.pkg -target / 
   hdiutil unmount /Volumes/Command\ Line\ Developer\ Tools/

   # accept the Xcode license
   sudo xcodebuild -license accept 
   xcode-select -p

   exit
   ```

4. Create an EBS snapshot and an AMI  

   At this stage, it is a good idea to create a snapshot and a GOLD AMI to avoid having to repeat this long installation process for each future mac1 EC2 instance that you would start.

   FROM YOUR LAPTOP (NOT FROM THE mac1 INSTANCE) :

   ```bash
   REGION=us-east-2
   # REPLACE THE IP ADDRESS IN THE COMMAND BELOW
   # Use the EC2 mac1 Instance Public IP
   EBS_VOLUME_ID=$(aws ec2 --region $REGION describe-instances --query 'Reservations[].Instances[?PublicIpAddress==`<YOUR EC2 MAC PUBLIC IP ADDRESS>`].BlockDeviceMappings[][].Ebs.VolumeId' --output text)
   aws ec2 create-snapshot --region $REGION --volume-id $EBS_VOLUME_ID --description "macOS Big Sur Xcode"

   # AT THIS STAGE COPY THE SNAPSHOT_ID RETURNED BY THE PREVIOUS COMMAND
   # WAIT FOR THE SNAPSHOT TO COMPLETE, THIS CAN TAKES SEVERAL MINUTES
   SNAPSHOT_ID=<YOUR SNAPSHOT ID>
   aws ec2 register-image --region=$REGION --name "GOLD_macOS_BigSur_Xcode" --description "macOS Big Sur Xcode Gold Image" --architecture x86_64_mac --virtualization-type hvm --block-device-mappings DeviceName="/dev/sda1",Ebs=\{SnapshotId=$SNAPSHOT_ID,VolumeType=gp3\} --root-device-name "/dev/sda1"
   ```

## Install build environment (one-time setup)

Now that we have our GOLD AMI, let's install the project specific build dependencies that we have. 

1. Connect to your mac1 EC2 instance using SSH

   `ssh -i /path/to/my/private-ssh-key.pem ec2-user@<mac1_instance_IP_address>`

2. Install project specific build dependencies

   The below file can be [downloaded](https://raw.githubusercontent.com/sebsto/amplify-ios-getting-started/main/code/cli-build/01_AMI_install_dev_dependencies.sh) GitHub.

   ```bash
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
   /usr/sbin/softwareupdate --install-rosetta --agree-to-license # on Apple Silicon, manually install Rosetta first
   curl -sL https://aws-amplify.github.io/amplify-cli/install | bash && $SHELL

   echo "Prepare AWS CLI configuration"
   mkdir ~/.aws
   echo "[default]\nregion=$DEFAULT_REGION\n\n" > ~/.aws/config
   echo "[default]\n\n" > ~/.aws/credentials
   ```

3. Create a Project GOLD AMI

   At this stage, it is a good idea to create a snapshot and a PROJECT GOLD AMI to avoid having to repeat this project specific installation process for each future mac1 EC2 instance that you would start.

   FROM YOUR LAPTOP (NOT FROM THE mac1 INSTANCE) :

   ```bash
   REGION=us-east-2
   # REPLACE THE IP ADDRESS IN THE COMMAND BELOW
   # Use the EC2 mac1 Instance Public IP
   EBS_VOLUME_ID=$(aws ec2 --region $REGION describe-instances --query 'Reservations[].Instances[?PublicIpAddress==`18.191.179.58`].BlockDeviceMappings[][].Ebs.VolumeId' --output text)
   aws ec2 create-snapshot --region $REGION --volume-id $EBS_VOLUME_ID --description "macOS Big Sur Xcode Amplify Project"

   # AT THIS STAGE COPY THE SNAPSHOT_ID RETURNED BY THE PREVIOUS COMMAND
   SNAPSHOT_ID=<YOUR SNAPSHOT ID>
   aws ec2 register-image --region=$REGION --name "GOLD_macOS_BigSur_Xcode_Amplify" --description "macOS Big Sur Xcode Amplify Project Gold Image" --architecture x86_64_mac --virtualization-type hvm --block-device-mappings DeviceName="/dev/sda1",Ebs=\{SnapshotId=$SNAPSHOT_ID,VolumeType=gp3\} --root-device-name "/dev/sda1"
   ```

4. Attach an EC2 role to the instance

   This is required to give processes running on your instances permission to access AWS resources in your account, such as Amazon S3 buckets, AWS SecretsManager secrets etc. It alos gives required permissions for Amplify to pull out it's resources and to the SQS Build agent to poll and post SQS messages.

   Once the role is created, it can be attached to future instances that you will launch, without typing these commands.

   FROM YOUR LAPTOP (NOT FROM THE mac1 INSTANCE) :

   ```bash
   # Create the IAM Policy and Role 
   IAM_ROLE_NAME="macOS_CICD_Amplify"
   EC2_PROFILE_NAME="$IAM_ROLE_NAME"_profile

   POLICY_ARN=$(aws iam create-policy --region $REGION --description "mac1 instance CICD permission for Amplify" --policy-name "mac1_CICD" --policy-document file://./cli-build/iam_permissions_for_ec2.json --query 'Policy.Arn' --output text)
   aws iam create-role --region $REGION --role-name $IAM_ROLE_NAME --assume-role-policy-document file://./cli-build/iam_assume_role.json
   aws iam attach-role-policy --region $REGION --policy-arn $POLICY_ARN --role-name $IAM_ROLE_NAME
   aws iam create-instance-profile --instance-profile-name $EC2_PROFILE_NAME
   INSTANCE_PROFILE_ARN=$(aws iam add-role-to-instance-profile --instance-profile-name $EC2_PROFILE_NAME --role-name $IAM_ROLE_NAME --query InstanceProfile.Arn --output text)

   # If you want to cleanup later, use the two below commands
   # aws iam remove-role-from-instance-profile --instance-profile-name $EC2_PROFILE_NAME --role-name $IAM_ROLE_NAME
   # aws iam delete-instance-profile --instance-profile-name $EC2_PROFILE_NAME 

   # Find your mac1 Instance ID (replace the IP address with your mac instance IP address)
   INSTANCE_ID=$(aws ec2 --region $REGION describe-instances --query 'Reservations[].Instances[?PublicIpAddress==`<YOUR MAC INSTANCE PUBLIC IP ADDRESS>`].InstanceId | []' --output text)

   # Finally, attach the profile to the instance
   aws ec2 associate-iam-instance-profile --region $REGION --instance-id $INSTANCE_ID --iam-instance-profile Arn=$INSTANCE_PROFILE_ARN,Name=$EC2_PROFILE_NAME
   ```

5. Import build secrets into AWS Secrets Manager

   [AWS Secrets Manager](https://aws.amazon.com/secrets-manager/) helps to securely store the secrets you need to access your application or resources.  For this project I will store a couple of project-specific secrets. Build time scripts will read from AWS Secrets Manager to retrieve a plain-text version of these.  Secrets are Amplify Project ID, Apple Distribution secret key and certificate, and the mobile provisionning profile downloaded from Apple developer web site. When uplaoding binaries automatically from iTunes Connect, I use AWS Secrets Manager to also store my Apple ID and apple application-specific password.

   While I am here, I will store two configuration options that are not secrets: the Amplify app name and environment name. I could have use other AWS services, such as [AWS Systems Manager Parameter Store](https://docs.aws.amazon.com/systems-manager/latest/userguide/systems-manager-parameter-store.html) to store these, but I did not want to extend IAM permissions and decided to store everything I need into Secrets Manager.

   **How to collect your build secrets ?**

   - To collect Amplify details, use `amplify env list --details`.
   - To generate an Apple application-specific password, visit https://appleid.apple.com/account/manage
   - Your Apple iOS Distribution certificate and private key can be exported from your development machine Keychain or from [Apple developer's console](https://developer.apple.com/account/resources/certificates).
   - Your mobile application provisioning profile can be downloaded from [Apple's developer's console](https://developer.apple.com/account/resources/profiles/list)

   ```bash
   REGION=us-east-2

   # do not change the name of the secrets. Builds scripts are using these names to retrieve the secrets.

   aws --region $REGION secretsmanager create-secret --name amplify-app-id --secret-string d3.......t9p --query ARN 
   aws --region $REGION secretsmanager create-secret --name amplify-project-name --secret-string iosgettingstarted
   aws --region $REGION secretsmanager create-secret --name amplify-environment --secret-string dev

   aws --region $REGION secretsmanager create-secret --name apple-signing-dev-certificate --secret-binary fileb://./secrets/apple_dev_seb.p12 
   aws --region $REGION secretsmanager create-secret --name apple-signing-dist-certificate --secret-binary fileb://./secrets/apple_dist_seb.p12 

   aws --region $REGION secretsmanager create-secret --name amplify-getting-started-dist-provisionning --secret-binary fileb://./secrets/getting-started-ios-dist.mobileprovision
   aws --region $REGION secretsmanager create-secret --name amplify-getting-started-dev-provisionning --secret-binary fileb://./secrets/getting-started-ios-dev.mobileprovision

   aws --region $REGION secretsmanager create-secret --name apple-id --secret-string myemail@me.com
   aws --region $REGION secretsmanager create-secret --name apple-secret --secret-string aaaa-aaaa-aaaa-aaaa
   ```

## Command Line Build

Now that the one-time setup is behind you, you can start to build the project. The high-level steps are (some commands here might not work as expected, the correct, executable, and up-to-date scripts are under `./cli-build`directory)

1.  Connect to your mac1 EC2 instance using SSH

    `ssh -i /path/to/my/private-ssh-key.pem ec2-user@<mac1_instance_IP_address>`

2. Pull Out the Code 

   ```bash
   HOME=/Users/ec2-user

   pushd $HOME 
   if [ -d amplify-ios-getting-started ]; then
      rm -rf amplify-ios-getting-started
   fi
   git clone https://github.com/sebsto/amplify-ios-getting-started.git
   CODE_DIR=$HOME/amplify-ios-getting-started/code

   echo "Changing to code directory at $CODE_DIR"
   cd $CODE_DIR
   ```

4. Install Amplify Libraries and other dependencies

   ```bash
   echo "Installing pods"
   /usr/local/bin/pod install
   ```

5. Pull Out the Amplify configuration 

   The below only works when the EC2 instance has [this minimum set of permissions](cli-build/iam_permissions_for_ec2.json)
  
   ```bash
   AWS_CLI=/usr/local/bin/aws
   REGION=$(curl -s 169.254.169.254/latest/meta-data/placement/region/)
   HOME=/Users/ec2-user

   CERTIFICATES_DIR=$HOME/certificates
   mkdir -p $CERTIFICATES_DIR 2>&1 >/dev/null

   echo $REGION 

   echo "Prepare keychain"
   KEYCHAIN_PASSWORD=Passw0rd
   KEYCHAIN_NAME=dev.keychain
   OLD_KEYCHAIN_NAMES=login.keychain
   SYSTEM_KEYCHAIN=/Library/Keychains/System.keychain
   AUTHORISATION=(-T /usr/bin/security -T /usr/bin/codesign -T /usr/bin/xcodebuild)

   if [ -f $HOME/Library/Keychains/"${KEYCHAIN_NAME}"-db ]; then
      echo "Deleting old ${KEYCHAIN_NAME} keychain"
      security delete-keychain "${KEYCHAIN_NAME}"
   fi

   echo "Creating keychain"
   security create-keychain -p "${KEYCHAIN_PASSWORD}" "${KEYCHAIN_NAME}"
   security list-keychains -s "${KEYCHAIN_NAME}" "${OLD_KEYCHAIN_NAMES[@]}"

   # at this point the keychain is unlocked, the below line is not needed
   security unlock-keychain -p "${KEYCHAIN_PASSWORD}" "${KEYCHAIN_NAME}"

   echo "Configure keychain : remove lock timeout"
   security set-keychain-settings "${KEYCHAIN_NAME}"

   if [ ! -f $CERTIFICATES_DIR/AppleWWDRCAG3.cer ]; then
      echo "Downloadind Apple Worlwide Developer Relation GA3 certificate"
      curl -s -o $CERTIFICATES_DIR/AppleWWDRCAG3.cer https://www.apple.com/certificateauthority/AppleWWDRCAG3.cer
   fi
   echo "Installing Apple Worlwide Developer Relation GA3 certificate into System keychain"
   sudo security import $CERTIFICATES_DIR/AppleWWDRCAG3.cer -t cert -k "${SYSTEM_KEYCHAIN}" "${AUTHORISATION[@]}"

   echo "Retrieve application dev and dist keys from AWS Secret Manager"
   SIGNING_DEV_KEY_SECRET=apple-signing-dev-certificate
   MOBILE_PROVISIONING_PROFILE_DEV_SECRET=amplify-getting-started-dev-provisionning
   SIGNING_DIST_KEY_SECRET=apple-signing-dist-certificate
   MOBILE_PROVISIONING_PROFILE_DIST_SECRET=amplify-getting-started-dist-provisionning

   # These are base64 values, we will need to decode to a file when needed
   SIGNING_DEV_KEY=$($AWS_CLI --region $REGION secretsmanager get-secret-value --secret-id $SIGNING_DEV_KEY_SECRET --query SecretBinary --output text)
   MOBILE_PROVISIONING_DEV_PROFILE=$($AWS_CLI --region $REGION secretsmanager get-secret-value --secret-id $MOBILE_PROVISIONING_PROFILE_DEV_SECRET --query SecretBinary --output text)
   SIGNING_DIST_KEY=$($AWS_CLI --region $REGION secretsmanager get-secret-value --secret-id $SIGNING_DIST_KEY_SECRET --query SecretBinary --output text)
   MOBILE_PROVISIONING_DIST_PROFILE=$($AWS_CLI --region $REGION secretsmanager get-secret-value --secret-id $MOBILE_PROVISIONING_PROFILE_DIST_SECRET --query SecretBinary --output text)

   echo "Import Signing private key and certificate"
   DEV_KEY_FILE=$CERTIFICATES_DIR/apple_dev_key.p12
   echo $SIGNING_DEV_KEY | base64 -d > $DEV_KEY_FILE
   security import "${DEV_KEY_FILE}" -P "" -k "${KEYCHAIN_NAME}" "${AUTHORISATION[@]}"

   DIST_KEY_FILE=$CERTIFICATES_DIR/apple_dist_key.p12
   echo $SIGNING_DIST_KEY | base64 -d > $DIST_KEY_FILE
   security import "${DIST_KEY_FILE}" -P "" -k "${KEYCHAIN_NAME}" "${AUTHORISATION[@]}"

   # is this necessary when importing keys with -A ?
   security set-key-partition-list -S apple-tool:,apple:,codesign: -s -k "${KEYCHAIN_PASSWORD}" "${KEYCHAIN_NAME}"

   echo "Install development provisioning profile"
   MOBILE_PROVISIONING_DEV_PROFILE_FILE=$CERTIFICATES_DIR/project-dev.mobileprovision
   echo $MOBILE_PROVISIONING_DEV_PROFILE | base64 -d > $MOBILE_PROVISIONING_DEV_PROFILE_FILE
   UUID=$(security cms -D -i $MOBILE_PROVISIONING_DEV_PROFILE_FILE -k "${KEYCHAIN_NAME}" | plutil -extract UUID xml1 -o - - | xmllint --xpath "//string/text()" -)
   mkdir -p "$HOME/Library/MobileDevice/Provisioning Profiles"
   cp $MOBILE_PROVISIONING_DEV_PROFILE_FILE "$HOME/Library/MobileDevice/Provisioning Profiles/${UUID}.mobileprovision"

   MOBILE_PROVISIONING_DIST_PROFILE_FILE=$CERTIFICATES_DIR/project-dist.mobileprovision
   echo $MOBILE_PROVISIONING_DIST_PROFILE | base64 -d > $MOBILE_PROVISIONING_DIST_PROFILE_FILE
   UUID=$(security cms -D -i $MOBILE_PROVISIONING_DIST_PROFILE_FILE -k "${KEYCHAIN_NAME}" | plutil -extract UUID xml1 -o - - | xmllint --xpath "//string/text()" -)
   cp $MOBILE_PROVISIONING_DIST_PROFILE_FILE "$HOME/Library/MobileDevice/Provisioning Profiles/${UUID}.mobileprovision"
   ````

7. Build

   ```bash
   # Increase Build Number
   BUILD_NUMBER=`date +%Y%m%d%H%M%S`
   plutil -replace CFBundleVersion -string $BUILD_NUMBER "./getting started/Info.plist"
   ```

   ```bash
   echo "Build, Sign and Archive"
   SCHEME="getting started"
   CONFIGURATION="Release"
   WORKSPACE="getting started.xcworkspace"
   BUILD_PATH="./build"
   ARCHIVE_PATH="$BUILD_PATH/getting-started.xcarchive"
   EXPORT_OPTIONS="./cli-build/ExportOptions.plist"

   xcodebuild clean build archive \
            -workspace "$WORKSPACE" \
            -scheme "$SCHEME" \
            -archivePath "$ARCHIVE_PATH" \
            -configuration "$CONFIGURATION"  
   ````

8. Archive

   ```bash
   echo "Creating an Archive"
   xcodebuild -exportArchive \
           -archivePath "$ARCHIVE_PATH" \
           -exportOptionsPlist "$EXPORT_OPTIONS" \
           -exportPath "$BUILD_PATH"

   echo "Verify Archive"
   xcrun altool  \
            --validate-app \
            -f "$(pwd)/build/$SCHEME.ipa" \
            -t ios \
            -u $APPLE_ID \
            -p @env:APPLE_SECRET
   ````

9. Upload

   Finally, this upload thsi build to your iTunesConnect account, ready for distribution (TestFlight, Release)

   ```bash
   echo "Upload Archive to iTunesConnect"
   export APPLE_ID=$($AWS_CLI --region $REGION secretsmanager get-secret-value --secret-id $APPLE_ID_SECRET --query SecretString --output text)
   export APPLE_SECRET=$($AWS_CLI --region $REGION secretsmanager get-secret-value --secret-id $APPLE_SECRET_SECRET --query SecretString --output text)

   xcrun altool  \
            --upload-app \
            -f "$(pwd)/build/$SCHEME.ipa" \
            -t ios \
            -u $APPLE_ID \
            -p @env:APPLE_SECRET   
   ````


## Alternative XCode Server (TBD - WORK IN PROGRESS)

https://www.raywenderlich.com/12258400-xcode-server-for-ios-getting-started

1. Create the server on Xcode in the cloud 
2. Add TCP Ports 20300 and 20343 - 20346 to your EC2 Security Group
  
    (discovered with `sudo lsof -PiTCP -sTCP:LISTEN`)
3. configure Xcode server on the EC2 instance 
4. Configure Xcode bot on mac laptop
5. Add pre-built script from `cli-build/bot-pre-build*.sh`. Pre build scripts increase the build number and pull out the Amplify configuration.
6. Add post-built script from `cli-build/bot-post-build.sh`. Post build script archive and upload the binary to iTunes Connect.
7. Add signing key (exported Apple Distribution key as p12 files from laptop)
security unlock-keychain -p <ec2-user-password>
security import apple-dist.p12 -k ~/Library/Keychains/login.keychain -T /usr/bin/codesign -P <key-password> 

** How to get rid of the UI password prompt ?? **
https://stackoverflow.com/questions/4369119/how-to-install-developer-certificate-private-key-and-provisioning-profile-for-io




