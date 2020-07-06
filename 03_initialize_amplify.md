# Initialize Amplify

## Install Amplify CLI
npm install -g @aws-amplify/cli

## Initialize the Amplify Project
pod init
+ project initialization steps at https://docs.amplify.aws/start/getting-started/setup/q/integration/ios#add-amplify-to-your-application

Check AmplifyConfig has been added to XCode project.

Podfile
```
# Uncomment the next line to define a global platform for your project
platform :ios, '13.0'

target 'getting started' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!

  # Pods for getting started
  pod 'Amplify', '~> 1.0'                             # required amplify dependency
  pod 'Amplify/Tools', '~> 1.0'                       # allows to call amplify CLI from within Xcode

end
```
## Initialize Amplify at Runtime

I create a `Backend` class to group the code to interract with our backend. I chose to use a singleton to make it easily available thorough the application.

The class initializer initializes Amplify:

```swift

import UIKit
import Amplify

class Backend {
    static let shared = Backend()
    static func initialize() -> Backend {
        return .shared
    }
    private init() {
      // initialize amplify
      do {
         try Amplify.configure()
         print("Initialized Amplify");
      } catch {
         print("Could not initialize Amplify: \(error)")
      }
    }
}
```

## First Amplify push
push=true
Build
push=false
