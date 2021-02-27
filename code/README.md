# Instructions to build on Amazon EC2

## Prepare a mac EC2 instance with Xcode (one time setup)

1. Get an mac1 instance ([doc](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-mac-instances.html)).

### Tips
- Remember, you need to allocate a dedicated host.  Minimum billing period is 24h. 

- Choose an EBS volume large enough, Xcode and development tools need space. I use a 500Gb gp3 volume.

- Create a Security Group with at least SSH (TCP 22). If you plan to use Xcode Server, add the following:
   - TCP 443 (HTTPS)
   - TCP 20300 (Xcode Server)
   - TCP 20343 - 20346 (Xcode Server)   

  It is always agood idea to restrict the source IP to your laptop / internet box (to find out your current IP address, use `curl ifconfig.me`)

- Do not forget to attach your SSH public key

Now that you have access to a macOS EC2 Instance, let's install Xcode.

2. Connect to your mac1 EC2 instance using SSH

   `ssh -i /path/to/my/private-ssh-key.pem`

3. Install Xcode

   ```bash
   echo "\n\nsetopt interactivecomments\n\n" >> ~/.zshrc 
   # First resize the file system to enjoy the full space offered by our EBS volume
   PDISK=$(diskutil list physical external | head -n1 | cut -d" " -f1)
   APFSCONT=$(diskutil list physical external | grep "Apple_APFS" | tr -s " " | cut -d" " -f8)
   yes | sudo diskutil repairDisk $PDISK
   sudo diskutil apfs resizeContainer $APFSCONT 0

   # Download and install Xcode (use your own S3 bucket / CloudFront distribution, the below will stop working at some point)
   curl -o xcode.xip https://download.stormacq.com/apple/Xcode_12.4.xip
   xip --expand xcode.xip 
   sudo mv Xcode.app /Applications

   # Download and install Xcode CLI (use your own S3 bucket / CloudFront distribution, the below will stop working at some point)
   curl -o xcode-cli.dmg https://download.stormacq.com/apple/Command_Line_Tools_for_Xcode_12.4.dmg
   hdiutil mount ./xcode-cli.dmg 
   sudo installer -pkg /Volumes/Command\ Line\ Developer\ Tools/Command\ Line\ Tools.pkg -target / 
   hdiutil unmount /Volumes/Command\ Line\ Developer\ Tools/

   sudo installer -pkg /Applications/Xcode.app/Contents/Resources/Packages/XcodeSystemResources.pkg -target /
   sudo installer -pkg /Applications/Xcode.app/Contents/Resources/Packages/CoreTypes.pkg -target /
   sudo installer -pkg /Applications/Xcode.app/Contents/Resources/Packages/MobileDevice.pkg -target /
   sudo installer -pkg /Applications/Xcode.app/Contents/Resources/Packages/MobileDeviceDevelopment.pkg -target /

   # it might take several minutes to display the license / to return.  Try until it works
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
   EBS_VOLUME_ID=$(aws ec2 --region $REGION describe-instances --query 'Reservations[].Instances[?PublicIpAddress==`18.191.179.58`].BlockDeviceMappings[][].Ebs.VolumeId' --output text)
   aws ec2 create-snapshot --region $REGION --volume-id $EBS_VOLUME_ID --description "macOS Big Sur Xcode"

   # AT THIS STAGE COPY THE SNAPSHOT_ID RETURNED BY THE PREVIOUS COMMAND
   # WAIT FOR THE SNAPSHOT TO COMPLETE, THIS CAN TAKES SEVERAL MINUTES
   SNAPSHOT_ID=<YOUR SNAPSHOT ID>
   aws ec2 register-image --region=$REGION --name "GOLD_macOS_BigSur_Xcode" --description "macOS Big Sur Xcode Gold Image" --architecture x86_64_mac --virtualization-type hvm --block-device-mappings DeviceName="/dev/sda1",Ebs=\{SnapshotId=$SNAPSHOT_ID,VolumeType=gp3\} --root-device-name "/dev/sda1"
   ```

## Install build environment (one-time setup)

Now that we have our GOLD AMI, let's install the project specific build dependencies that we have.

1. Connect to your mac1 EC2 instance using SSH

   `ssh -i /path/to/my/private-ssh-key.pem`

2. Install project specific build dependencies

   (cocoapads dependency solved [thanks to this answer](https://stackoverflow.com/questions/20939568/error-error-installing-cocoapods-error-failed-to-build-gem-native-extension/62706706#62706706))

   The below file can be [downloaded](https://raw.githubusercontent.com/sebsto/amplify-ios-getting-started/main/code/cli-build/build_prepare_machine.sh) GitHub.

   ```bash
   echo "Update Ruby"
   brew install ruby
   echo '\nexport PATH="/usr/local/opt/ruby/bin:$PATH"' >> ~/.zshrc
   export LDFLAGS="-L/usr/local/opt/ruby/lib"
   export CPPFLAGS="-I/usr/local/opt/ruby/include"

   echo "Install cocoapods"
   sudo gem install -n /usr/local/bin cocoapods 

   echo "Install NodeJS and JQ"
   brew install node jq

   echo "Install Amplify CLI"
   npm install -g @aws-amplify/cli

   echo "Prepare AWS CLI configuration"
   mkdir ~/.aws
   echo "[default]\nregion=eu-central-1\n\n" > ~/.aws/config
   echo "[default]\n\n" > ~/.aws/credentials

   exit
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

   # Find your mac1 Instance ID
   INSTANCE_ID=$(aws ec2 --region $REGION describe-instances --query 'Reservations[].Instances[?PublicIpAddress==`18.191.179.58`].InstanceId | []' --output text)

   # Finally, attach the profile to the instance
   aws ec2 associate-iam-instance-profile --region $REGION --instance-id $INSTANCE_ID --iam-instance-profile Arn=$INSTANCE_PROFILE_ARN,Name=$EC2_PROFILE_NAME
   ```

## Command Line Build

Now that one time setup is behind you, you can start to build the project.
A full executable script [is available from the project](https://github.com/sebsto/amplify-ios-getting-started/blob/main/code/cli-build/build_archive_upload.sh).  I am breaking it in multiple sections for learning purposes.

1.  Connect to your mac1 EC2 instance using SSH

   `ssh -i /path/to/my/private-ssh-key.pem`

2. Add your environment specific settings 

   ```bash
   curl -o build_secrets.sh https://raw.githubusercontent.com/sebsto/amplify-ios-getting-started/main/code/cli-build/build_secrets_RENAME_AND_ADJUST.sh
   chmod u+x build_secrets.sh
   ```
   Assign a value to all the variables in that file. To do so, you will need to export your Apple distribution key from your local laptop Keychain, and downlaod your app provisioning profile from Apple's developer web site.

   An example file, once completed should look like this:

   ```
   #!/bin/sh

   ## My project and environment specific values
   ## Replace all of these with yours 

   # get the app id with : amplify env list --details

   AMPLIFY_APPID=d3....9p
   AMPLIFY_PROJECT_NAME=iosgettingstarted
   AMPLIFY_ENV=dev

   S3_APPLE_DISTRIBUTION_CERT=s3://your_private_s3_bucket/apple-dist.p12
   S3_MOBILE_PROVISIONING_PROFILE=s3://your_private_s3_bucket/Amplify_Getting_Started.mobileprovision
   APPLE_DISTRIBUTION_KEY_PASSWORD=""

   export APPLE_ID=my_icloud_email@mail.com
   export APPLE_SECRET=aaaa-bbbb-cccc-dddd  # app specific password generated on appleid.apple.com 
   ```

   !! Source this file before proceeding with the following !!

   ```bash
   source ./build_secrets.sh
   ```

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

3. Install Amplify Libraries and other dependencies

   ```bash
   echo "Installing pods"
   /usr/local/bin/pod install
   ```

4. Pull Out the Amplify configuration 

The below only works when the EC2 instance has [this minimum set of permissions](cli-build/iam_permissions_for_ec2.json)
  
  ```bash
   echo "Backing up generated files (these are deleted by amplify pull)"
   mv amplify/generated .

   echo "Pulling amplify environment"

   # see https://docs.amplify.aws/cli/usage/headless#amplify-pull-parameters 

   AWSCLOUDFORMATIONCONFIG="{\
   \"configLevel\":\"project\",\
   \"useProfile\":true,\
   \"profileName\":\"default\"\
   }"
   AMPLIFY="{\
   \"projectName\":\"$AMPLIFY_PROJECT_NAME\",\
   \"appId\":\"$AMPLIFY_APPID\",\
   \"envName\":\"$AMPLIFY_ENV\",\
   \"defaultEditor\":\"code\"\
   }"
   FRONTEND="{\
   \"frontend\":\"ios\"
   }"

   PATH=$PATH:/usr/local/bin/ # require to find node
   /usr/local/bin/amplify pull \
   --amplify $AMPLIFY \
   --frontend $FRONTEND \
   --providers $PROVIDERS \
   --yes --region eu-central-1

   echo "Restore generated files"
   mv ./generated amplify/
   ```

5. Prepare the Keychain with signing certificates 

   ```bash
   echo "Prepare keychain"
   DIST_CERT=~/apple-dist.p12
   KEYCHAIN_PASSWORD=Passw0rd\!
   KEYCHAIN_NAME=dev
   OLD_KEYCHAIN_NAMES=login
   if [ -f ~/Library/Keychains/"${KEYCHAIN_NAME}"-db ]; then
      rm ~/Library/Keychains/"${KEYCHAIN_NAME}"-db
   fi
   security create-keychain -p "${KEYCHAIN_PASSWORD}" "${KEYCHAIN_NAME}"
   security unlock-keychain -p "${KEYCHAIN_PASSWORD}" "${KEYCHAIN_NAME}"
   security list-keychains -s "${KEYCHAIN_NAME}" "${OLD_KEYCHAIN_NAMES[@]}"

   curl -o ~/AppleWWDRCA.cer https://developer.apple.com/certificationauthority/AppleWWDRCA.cer 
   security import ~/AppleWWDRCA.cer -t cert -k "${KEYCHAIN_NAME}" -T /usr/bin/codesign -T /usr/bin/xcodebuild
   curl -o ~/AppleWWDRCAG3.cer https://www.apple.com/certificateauthority/AppleWWDRCAG3.cer
   security import ~/AppleWWDRCAG3.cer -t cert -k "${KEYCHAIN_NAME}" -T /usr/bin/codesign -T /usr/bin/xcodebuild
   curl -o ~/DevAuthCA.cer https://www.apple.com/certificateauthority/DevAuthCA.cer 
   security import ~/DevAuthCA.cer -t cert -k "${KEYCHAIN_NAME}" -T /usr/bin/codesign -T /usr/bin/xcodebuild

   aws s3 cp $S3_APPLE_DISTRIBUTION_CERT $DIST_CERT
   security import "${DIST_CERT}" -P "${APPLE_DISTRIBUTION_KEY_PASSWORD}" -k "${KEYCHAIN_NAME}" -T /usr/bin/codesign -T /usr/bin/xcodebuild

   security set-keychain-settings $KEYCHAIN_NAME 
   security set-key-partition-list -S apple-tool:,apple: -s -k "${KEYCHAIN_PASSWORD}" "${KEYCHAIN_NAME}"


   echo "Install provisioning profile"
   MOBILE_PROVISIONING_PROFILE=~/project.mobileprovision
   aws s3 cp $S3_MOBILE_PROVISIONING_PROFILE $MOBILE_PROVISIONING_PROFILE
   UUID=$(security cms -D -i $MOBILE_PROVISIONING_PROFILE -k "${KEYCHAIN_NAME}" | plutil -extract UUID xml1 -o - - | xmllint --xpath "//string/text()" -)
   mkdir -p "$HOME/Library/MobileDevice/Provisioning Profiles"
   cp $MOBILE_PROVISIONING_PROFILE "$HOME/Library/MobileDevice/Provisioning Profiles/${UUID}.mobileprovision" 
   ````

6. Build

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

7. Archive

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

8. Upload

   Finally, this upload thsi build to your iTunesConnect account, ready for distribution (TestFlight, Release)

   ```bash
   echo "Upload Archive to iTunesConnect"
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
5. Add pre-built script from cli-build/
6. Add post-nuilt script from cli-build/
7. Add signing key (exported Apple Distribution key as p12 files from laptop)
security unlock-keychain -p <ec2-user-password>
security import apple-dist.p12 -k ~/Library/Keychains/login.keychain -T /usr/bin/codesign -P <key-password> 

** How to get rid of the UI password prompt ?? **
https://stackoverflow.com/questions/4369119/how-to-install-developer-certificate-private-key-and-provisioning-profile-for-io




