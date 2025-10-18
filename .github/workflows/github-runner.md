## GitHub Runner as macOS Daemon 

[GitHub instructions to install a runner on macOS](https://docs.github.com/en/actions/hosting-your-own-runners/configuring-the-self-hosted-runner-application-as-a-service) doesn't work on headless machines because it launches as LaunchAgent (these require a GUI Session)

Solution : install as a Launch Dameon

```sh
sudo bash 

RUNNER_NAME=actions.runner.sebsto-amplify-ios-getting-started
cat << EOF > /Library/LaunchDaemons/$RUNNER_NAME.plist
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
  <dict>
    <key>Label</key>
    <string>actions-runner-amplify-ios-getting-started</string>
    <key>ProgramArguments</key>
    <array>
      <string>/Users/ec2-user/actions-runner-amplify-ios-getting-started/run.sh</string>
    </array>
    <key>KeepAlive</key>
    <dict>
      <key>SuccessfulExit</key>
      <false/>
    </dict> 
    <key>UserName</key>
    <string>ec2-user</string>
    <key>GroupName</key>
    <string>staff</string>  
    <key>WorkingDirectory</key>
    <string>/Users/ec2-user/actions-runner-amplify-ios-getting-started</string>
    <key>RunAtLoad</key>
    <true/>    
    <key>StandardOutPath</key>
    <string>/Users/ec2-user/actions-runner-amplify-ios-getting-started/stdout.log</string>
    <key>StandardErrorPath</key>
    <string>/Users/ec2-user/actions-runner-amplify-ios-getting-started/stderr.log</string>
    <key>EnvironmentVariables</key>
    <dict> 
      <key>ACTIONS_RUNNER_SVC</key>
      <string>1</string>
      <key>PATH</key>
      <string>/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin</string>
    </dict>
    <key>SessionCreate</key>
    <true/>
  </dict>
</plist>
EOF

sudo chown root:wheel /Library/LaunchDaemons/$RUNNER_NAME.plist 
sudo /bin/launchctl load /Library/LaunchDaemons/$RUNNER_NAME.plist
```