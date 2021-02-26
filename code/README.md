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

   sudo xcodebuild -license accept 
   xcode-select -p
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
   SNAPSHOT_ID=<YOUR SNAPSHOT ID>
   aws ec2 register-image --region=$REGION --name "GOLD_macOS_BigSur_Xcode" --description "macOS Big Sur Xcode Gold Image" --block-device-mappings DeviceName="/dev/sda",Ebs=\{SnapshotId=$SNAPSHOT_ID,VolumeType=gp3\} --root-device-name "/dev/sda1"
   ```

## Install build environment (one-time setup)

Now that we have our GOLD AMI, let's install the project specific build dependencies that we have.

1. Install project specific build dependencies

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
```

2. Create a Project GOLD AMI

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
   aws ec2 register-image --region=$REGION --name "GOLD_macOS_BigSur_Xcode_Amplify" --description "macOS Big Sur Xcode Amplify Project Gold Image" --block-device-mappings DeviceName="/dev/sda",Ebs=\{SnapshotId=$SNAPSHOT_ID,VolumeType=gp3\} --root-device-name "/dev/sda1"
   ```

4. Attach an EC2 role to the instance

   FROM YOUR LAPTOP (NOT FROM THE mac1 INSTANCE) :

   ```bash
   # Create the IAM Policy and Role 
   IAM_ROLE_NAME="macOS_CICD_Amplify"
   EC2_PROFILE_NAME="$IAM_ROLE_NAME"_profile
   POLICY_ARN=$(aws iam create-policy --region $REGION --description "mac1 instance CICD permission for Amplify" --policy-name "mac1_CICD" --policy-document file://./iam_permissions_for_ec2.json --query 'Policy.Arn' --output text)
   aws iam create-role --region $REGION --role-name $IAM_ROLE_NAME --assume-role-policy-document file://./iam_assume_role.json
   aws iam attach-role-policy --region $REGION --policy-arn $POLICY_ARN --role-name $IAM_ROLE_NAME
   aws iam create-instance-profile --instance-profile-name $EC2_PROFILE_NAME
   INSTANCE_PROFILE_ARN=$(aws iam add-role-to-instance-profile --instance-profile-name $EC2_PROFILE_NAME --role-name $IAM_ROLE_NAME --query InstanceProfile.Arn --output text)

   # Find your mac1 Instance ID
   INSTANCE_ID=$(aws ec2 --region $REGION describe-instances --query 'Reservations[].Instances[?PublicIpAddress==`18.191.179.58`].InstanceId | []' --output text)

   # Finally, attach the profile to the instance
   aws ec2 associate-iam-instance-profile --region $REGION --instance-id $INSTANCE_ID --iam-instance-profile Arn=$INSTANCE_PROFILE_ARN,Name=$EC2_PROFILE_NAME
   ```

## Command Line Build



## Alternative XCode Server 

https://www.raywenderlich.com/12258400-xcode-server-for-ios-getting-started

1. Create the server on Xcode in the cloud 
2. Add TCP Ports 20300 and 20343 - 20346 to your EC2 Security Group
  
    (discovered with `sudo lsof -PiTCP -sTCP:LISTEN`)
3. configure Xcode server on the EC2 instance 
4. Configure Xcode bot on mac laptop
5. Add pre-built script from cli-build/
6. Add signing key (exported Apple Distribution key as p12 files from laptop)
security unlock-keychain -p <ec2-user-password>
security import apple-dist.p12 -k ~/Library/Keychains/login.keychain -T /usr/bin/codesign -P <key-password> 

** How to get rid of the UI password prompt ?? **
https://stackoverflow.com/questions/4369119/how-to-install-developer-certificate-private-key-and-provisioning-profile-for-io




