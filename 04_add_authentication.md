# Add Authentication

## Create the Authentication Service

```zsh
amplify add auth

# choose federated authentication
# use 'gettingstarted://' as redirection URI
```

## Deploy the Authentication Service

```zsh
amplify push
```

## Add Amplify Libs to the Project
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

  pod 'AmplifyPlugins/AWSCognitoAuthPlugin', '~> 1.0' # support for Cognito user authentication
storage

end
```

`pod install`

## Add Amplify Authentication plugin at runtime

In `Backend` class, replace the amplify initialization code we added in the previous section with:

```swift
// at the top of the file
import AmplifyPlugins

// in the initializer

private init () {
  // initialize amplify
  do {
     try Amplify.add(plugin: AWSCognitoAuthPlugin())
     try Amplify.configure()
     print("Initialized Amplify");
  } catch {
     print("Could not initialize Amplify: \(error)")
  }
}
```

## Trigger Authentication at Runtime
1. add signin code

Anywhere in `Backend` class

```swift
// signin with Cognito web user interface
public func signIn() {

    _ = Amplify.Auth.signInWithWebUI(presentationAnchor: UIApplication.shared.windows.first!) { result in
        switch result {
        case .success(_):
            print("Sign in succeeded")
        case .failure(let error):
            print("Sign in failed \(error)")
        }
    }
}

// signout
public func signOut() {

    _ = Amplify.Auth.signOut() { (result) in
        switch result {
        case .success:
            print("Successfully signed out")
        case .failure(let error):
            print("Sign out failed with error \(error)")
        }
    }
}
```

2. add authentication hub listener

In `Backend`, add

```Swift
// in the AppDelegate class
// change our internal state, this triggers an UI update on the main thread
func updateUI(forSignInStatus : Bool) {
    DispatchQueue.main.async() {
        let userData = UserData.shared
        userData.isSignedIn = forSignInStatus        
    }
}

// in private init() function
// listen to auth events.
// see https://github.com/aws-amplify/amplify-ios/blob/master/Amplify/Categories/Auth/Models/AuthEventName.swift
_ = Amplify.Hub.listen(to: .auth) { (payload) in

    switch payload.eventName {

    case HubPayload.EventName.Auth.signedIn:
        print("==HUB== User signed In, update UI")
        self.updateUI(forSignInStatus: true)

    case HubPayload.EventName.Auth.signedOut:
        print("==HUB== User signed Out, update UI")
        self.updateUI(forSignInStatus: false)

    case HubPayload.EventName.Auth.sessionExpired:
        print("==HUB== Session expired, show sign in aui")
        self.updateUI(forSignInStatus: false)

    default:
        //print("==HUB== \(payload)")
        break
    }
}
```

3. Update UI

Open `ContentView.swift` and replace `body` in `struct ContentView`

```swift
var body: some View {

    ZStack {
        if (userData.isSignedIn) {
            NavigationView {
                List {
                    ForEach(userData.notes) { note in
                        ListRow(note: note)
                    }
                }
                .navigationBarTitle(Text("Notes"))
                .navigationBarItems(leading: SignOutButton())
            }
        } else {
            SignInButton()
        }
    }
}
```

In the same file, add a `SignInButton` view:

```swift
struct SignInButton: View {
    var body: some View {
        Button(action: { Backend.shared.signIn() }){
            HStack {
                Image(systemName: "person.fill")
                    .scaleEffect(1.5)
                    .padding()
                Text("Sign In")
                    .font(.largeTitle)
            }
            .padding()
            .foregroundColor(.white)
            .background(Color.green)
            .cornerRadius(30)
        }
    }
}
```

In the same file, add a `SignOutButton` button:

```swift
struct SignOutButton : View {
    var body: some View {
        Button(action: { Backend.shared.signOut() }) {
                Text("Sign Out")
        }
    }
}
```

5. Update `Info.plist`

```xml
<plist version="1.0">

     <dict>
     <!-- YOUR OTHER PLIST ENTRIES HERE -->

     <!-- ADD AN ENTRY TO CFBundleURLTypes for Cognito Auth -->
     <!-- IF YOU DO NOT HAVE CFBundleURLTypes, YOU CAN COPY THE WHOLE BLOCK BELOW -->
     <key>CFBundleURLTypes</key>
     <array>
         <dict>
             <key>CFBundleURLSchemes</key>
             <array>
                 <string>gettingstarted</string>
             </array>
         </dict>
     </array>

     <!-- ... -->
     </dict>
```
6. Build, Launch, SignUp, SignIn
