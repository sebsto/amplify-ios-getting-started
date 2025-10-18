[![Build Status](https://github.com/sebsto/amplify-ios-getting-started/actions/workflows/ContinuousIntegration.yml/badge.svg)](https://github.com/sebsto/amplify-ios-getting-started/actions/workflows/ContinuousIntegration.yml)
![language](https://img.shields.io/badge/swift-5.7-blue)
![platform](https://img.shields.io/badge/platform-ios-green)
[![license](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](LICENSE)

# Instructions to build on Amazon EC2

The below are step by step instructions to build this project on macOS.  It describe how to start an Amazon EC2 Mac instance and how to use the command line to install your development environment and to build the project.  If you are using your own Mac, you can skip the Amazon EC2 section.

## Prepare an EC2 Mac instance with Xcode (one time setup)

1. Get an EC2 Mac instance ([doc](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-mac-instances.html)).

### Tips
- Remember, you need to allocate a dedicated host.  Minimum billing period is 24h. 

- Choose an EBS volume large enough, Xcode and development tools need space. I use a 500Gb gp3 volume.

- Create a Security Group athorizing ingress traffic for SSH (TCP 22)

  It is always a good idea to restrict the source IP to your laptop / internet box (to find out your current IP address, use `curl ifconfig.me`)

- Do not forget to attach your SSH public key

Now that you have access to a macOS EC2 Instance, let's install Xcode.

2. Connect to your EC2 Mac instance using SSH

   `ssh -i /path/to/my/private-ssh-key.pem ec2-user@<mac1_instance_IP_address>`

3. Install Xcode

   See instructions `cli-build/00_AMI_install_dev_tools.sh`

   Alternatively, you can use [xcodeinstall](https://github.com/sebsto/xcodeinstall)

4. (optional) Create an EBS snapshot and an GOLD AMI  

   At this stage, it is a good idea to create a snapshot and a GOLD AMI to avoid having to repeat this long installation process for each future EC2 Mac instance that you would start.

   FROM YOUR LAPTOP (NOT FROM THE EC2 MAC INSTANCE) :

   ```bash
   REGION=us-west-2
   # REPLACE THE IP ADDRESS IN THE COMMAND BELOW
   # Use the EC2 Mac Instance Public IP
   EBS_VOLUME_ID=$(aws ec2 --region $REGION describe-instances --query 'Reservations[].Instances[?PublicIpAddress==`<YOUR EC2 MAC PUBLIC IP ADDRESS>`].BlockDeviceMappings[][].Ebs.VolumeId' --output text)
   aws ec2 create-snapshot --region $REGION --volume-id $EBS_VOLUME_ID --description "macOS Big Sur Xcode"

   # COPY THE SNAPSHOT_ID RETURNED BY THE PREVIOUS COMMAND
   # WAIT FOR THE SNAPSHOT TO COMPLETE, THIS CAN TAKES SEVERAL MINUTES
   SNAPSHOT_ID=<YOUR SNAPSHOT ID>
   aws ec2 register-image --region=$REGION --name "GOLD_macOS_BigSur_Xcode" --description "macOS Big Sur Xcode Gold Image" --architecture x86_64_mac --virtualization-type hvm --block-device-mappings DeviceName="/dev/sda1",Ebs=\{SnapshotId=$SNAPSHOT_ID,VolumeType=gp3\} --root-device-name "/dev/sda1"
   ```

4. Attach an EC2 role to the instance

   This is required to give processes running on your instances permission to access AWS resources in your account, such as Amazon S3 buckets, AWS SecretsManager secrets etc. It alos gives required permissions for Amplify to pull out its resources (if you use AWS Amplify).

   Once the role is created, it can be attached to future instances that you will launch, without typing these commands.

   FROM YOUR LAPTOP (NOT FROM THE EC2 Mac INSTANCE) :

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

   # Find your Mac Instance ID (replace the IP address with your mac instance IP address)
   INSTANCE_ID=$(aws ec2 --region $REGION describe-instances --query 'Reservations[].Instances[?PublicIpAddress==`<YOUR MAC INSTANCE PUBLIC IP ADDRESS>`].InstanceId | []' --output text)

   # Finally, attach the profile to the instance
   aws ec2 associate-iam-instance-profile --region $REGION --instance-id $INSTANCE_ID --iam-instance-profile Arn=$INSTANCE_PROFILE_ARN,Name=$EC2_PROFILE_NAME
   ```

5. Import build secrets into AWS Secrets Manager

   [AWS Secrets Manager](https://aws.amazon.com/secrets-manager/) helps to securely store the secrets you need to access your application or resources.  For this project I will store a couple of project-specific secrets. Build time scripts will read from AWS Secrets Manager to retrieve a plain-text version of these.  Secrets are Amplify Project ID, Apple Distribution secret key and certificate, and the mobile provisionning profile downloaded from Apple developer web site. When uplaoding binaries automatically from App Store Connect, I use AWS Secrets Manager to also store my Apple ID and apple application-specific password.

   **How to collect your build secrets ?**

   - To generate an Apple application-specific password, visit https://appleid.apple.com/account/manage
   - Your Apple iOS Distribution certificate and private key can be exported from your development machine Keychain or from [Apple developer's console](https://developer.apple.com/account/resources/certificates).
   - Your mobile application provisioning profile can be downloaded from [Apple's developer's console](https://developer.apple.com/account/resources/profiles/list)

   See `cli-build/import_secrets.sh`

## Command Line Build

Now that the one-time setup is behind you, you can start to build the project.

1.  Connect to your mac1 EC2 instance using SSH

    `ssh -i /path/to/my/private-ssh-key.pem ec2-user@<mac1_instance_IP_address>`

2. Pull Out the code 

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

4. Run the scripts in the `ci_actions` directory, one by one, in the correct order.
