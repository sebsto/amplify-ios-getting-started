


```sh

sudo bash 

RUNNER_NAME=gitlab.runner.sebsto-amplify-ios-getting-started
cat << EOF > /Library/LaunchDaemons/$RUNNER_NAME.plist
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
  <dict>
    <key>SessionCreate</key>
    <true/>
    <key>KeepAlive</key>
    <dict>
      <key>SuccessfulExit</key>
      <false/>
    </dict>
    <key>RunAtLoad</key>
    <true/>
    <key>Disabled</key>
    <false/>
    <key>Label</key>
    <string>com.gitlab.gitlab-runner</string>
    <key>UserName</key>
    <string>ec2-user</string>
    <key>GroupName</key>
    <string>staff</string>
    <key>ProgramArguments</key>
    <array>
      <string>/opt/homebrew/bin/gitlab-runner</string>
      <string>run</string>
      <string>--working-directory</string>
      <string>/Users/ec2-user/gitlab-runner</string>
      <string>--config</string>
      <string>/Users/ec2-user/.gitlab-runner/config.toml</string>
      <string>--service</string>
      <string>gitlab-runner</string>
      <string>--syslog</string>
    </array>
    <key>EnvironmentVariables</key>
    <dict>
      <key>PATH</key>
      <string>/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin</string>
    </dict>
  </dict>
</plist>
EOF

sudo chown root:wheel /Library/LaunchDaemons/$RUNNER_NAME.plist 
sudo /bin/launchctl load /Library/LaunchDaemons/$RUNNER_NAME.plist

cat << EOF > /Users/ec2-user/gitlab-runner/config.toml
concurrent = 2
log_level = "info"
EOF

```