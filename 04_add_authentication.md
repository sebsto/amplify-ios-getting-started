# Introduction

The next feature you will be adding is user authentication. In this module, you will learn how to authenticate a user with the Amplify CLI and libraries, leveraging [Amazon Cognito](https://aws.amazon.com/cognito/), a managed user identity provider.

You will also learn how to use the Cognito Hosted User Interface to present an entire user authentication flow, allowing users to sign up, sign in, and reset their password with just few lines of code.

using a "Hosted User Interface" means the application leverages the Cognito web pages for the signin and signup user interface flows. The user of the app is redirected to a web page hosted by Cognito and redirected back to the app after signin.  Of course, Cognito and Amplify does support native UI as well, you can follow [these workshop instructions](https://amplify-ios-workshop.go-aws.com/70_add_custom_gui/30_customized_ui.html) to learn more about custom authentication UI.

## What you Will Learn

- Create and deploy an authentication service
- Configure your iOS app to include Cognito Hosted UI authentication

## Key Concepts

- Amplify libraries – The Amplify libraries allow you to interact with AWS services from a web or mobile application.

- Authentication – In software, authentication is the process of verifying and managing the identity of a user using an authentication service or API.

# Implementation

## Create the Authentication Service

To create the authentication service, open a Terminal and **execute this command** in your project directory:

```zsh
amplify add auth
```

- *? Do you want to use the default authentication and security configuration?* Select **Default configuration with Social Provider** and press **enter**
- *How do you want users to be able to sign in?* Select the default **Username** and press **enter**
- *Do you want to configure advanced settings?* Select the default **No, I am done** and press **enter**
- *What domain name prefix do you want to use?* Select the default and press **enter**
- *Enter your redirect signin URI:* type **`gettingstarted://`** and press **enter**
- *? Do you want to add another redirect signin URI?* Select the default **N** and press **enter**
- *Enter your redirect signout URI:* type **`gettingstarted://`** and press **enter**
- *? Do you want to add another redirect signout URI?* Select the default **N** and press **enter**
- *Select the social providers you want to configure for your user pool:* do not select any provider and press **enter**

You know the configuration is successful when you see the message (the exact name of the resource will vary) :

```text
Successfully added resource iosgettingstartedfc5a4717 locally
```

## Deploy the Authentication Service

Now that the authentication service has been configured locally, you can deploy it to the cloud. In a Terminal, **execute this command** in your project directory:

```zsh
amplify push

# press Y when asked to continue
```

After a while, you should see the following message:

```zsh
✔ All resources are updated in the cloud

Hosted UI Endpoint: https://iosgettingstarted-dev.auth.eu-central-1.amazoncognito.com/
Test Your Hosted UI Endpoint: https://iosgettingstarted-dev.auth.eu-central-1.amazoncognito.com/login?response_type=code&client_id=1234567890&redirect_uri=gettingstarted://
```

## Add Amplify Authentication Library to the Project

Before going to the code, you add the Amplify Authentication Library to the dependencies of your project.  Open the `Podfile` file and **add the line** with `AmplifyPlugins/AWSCognitoAuthPlugin` or copy / paste the entire file below.

```Podfile
# you need at least version 13.0 for this tutorial, more recent versions are valid too
platform :ios, '13.0'

target 'getting started' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!

  # Pods for getting started
  pod 'Amplify', '~> 1.0'                             # required amplify dependency
  pod 'Amplify/Tools', '~> 1.0'                       # allows to call amplify CLI from within Xcode

  pod 'AmplifyPlugins/AWSCognitoAuthPlugin', '~> 1.0' # support for Cognito user authentication

end
```

In a terminal, **execute the command**:

```zsh
pod install
```

The command takes a few seconds to complete. You should see this (actual version numbers may vary):

```zsh
Analyzing dependencies
Downloading dependencies
Installing AWSAuthCore (2.14.1)
Installing AWSCognitoIdentityProvider (2.14.1)
Installing AWSCognitoIdentityProviderASF (1.0.1)
Installing AWSCore (2.14.1)
Installing AWSMobileClient (2.14.1)
Installing AWSPluginsCore (1.0.4)
Installing AmplifyPlugins (1.0.4)
Generating Pods project
Integrating client project
Pod installation complete! There are 3 dependencies from the Podfile and 8 total pods installed.
```

## Configure Amplify Authentication library at runtime

Back to Xcode, open `Backend.swift` file.  In the `Backend` class,

- **add** an `import` statement for the `AmplifyPlugins`
- **add a line** to the amplify initialization code we added in the previous section.

Complete code block should look like this:

```swift
// at the top of the file
import AmplifyPlugins

private init () {
  // initialize amplify
  do {
     try Amplify.add(plugin: AWSCognitoAuthPlugin())
     try Amplify.configure()
     print("Initialized Amplify")
  } catch {
     print("Could not initialize Amplify: \(error)")
  }
}
```

To verify everything works as expected, build the project. Click **Product** menu and select **Build** or type **&#8984;B**. There should be no error.

## Trigger Authentication at Runtime

The remaining code change tracks the status of user (are they signed in or not?) and triggers the SignIn / SignUp user interface when user is not signed in.

1. Add signin and signout code

    Anywhere in `Backend` class, add the following three methods:

    ```swift

    // MARK: - User Authentication

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

    // change our internal state, this triggers an UI update on the main thread
    func updateUserData(withSignInStatus status : Bool) {
        DispatchQueue.main.async() {
            let userData : UserData = .shared
            userData.isSignedIn = status
        }
    }
    ```

2. Add an authentication hub listener

    To track the changes of authentication status, we add code to subscribe to Authentication events sent by Amplify. We initialize the Hub in the `Backend.init()` method.

    When an authentication event is received, we call the `updateUserData()` method.  This method keeps the `UserData` object in sync.  The `UserData.isSignedIn` property is `@Published`, it means the user interface is automatically refreshed when the value changes.

    In `Backend.init()`, **add the following code** after Amplify's initialization:

    ```Swift
    // in private init() function
    // listen to auth events.
    // see https://github.com/aws-amplify/amplify-ios/blob/master/Amplify/Categories/Auth/Models/AuthEventName.swift
    _ = Amplify.Hub.listen(to: .auth) { (payload) in

        switch payload.eventName {

        case HubPayload.EventName.Auth.signedIn:
            print("==HUB== User signed In, update UI")
            self.updateUserData(withSignInStatus: true)

        case HubPayload.EventName.Auth.signedOut:
            print("==HUB== User signed Out, update UI")
            self.updateUserData(withSignInStatus: false)

        case HubPayload.EventName.Auth.sessionExpired:
            print("==HUB== Session expired, show sign in UI")
            self.updateUserData(withSignInStatus: false)

        default:
            //print("==HUB== \(payload)")
            break
        }
    }
    ```

3. Update the User Interface code

    The last change in the code is related to the User Interface, we add a `ZStack` to the `ContentView`.  Depending on `UserData.isSignedIn`'s value, the UI shows either a `SigninButton` or the main `List` view.

    Open `ContentView.swift` and **replace** `body` in `ContentView` struct:

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

    In the same file, **add** a `SignInButton` and a `SignOutButton` view:

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

    struct SignOutButton : View {
        var body: some View {
            Button(action: { Backend.shared.signOut() }) {
                    Text("Sign Out")
            }
        }
    }
    ```

    To verify everything works as expected, build the project. Click **Product** menu and select **Build** or type **&#8984;B**. There should be no error.

4. Update `Info.plist`

    Finally, we must ensure our app is launched at the end of the web authentication sequence, provided by Cognito hosted user interface.  We add the `gettingstarted` URI scheme to the app's `Info.plist` file.

    In Xcode, select the `Info.plist` file, right click on it and **select Open As**, **Source Code**.

    ![Open as Source Code](img/03_20.png)

    Add the below `<key>` and `<array>` elements **inside** the top `<dict>` element.

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

5. Build and Test

    To verify everything works as expected, build the project. Click **Product** menu and select **Run** or type **&#8984;R**. There should be no error. The app starts on the Sign In button.

Here is the full signup flow.

| Landing View | Consent to redirect| Cognito Hosted UI |
| --- | --- | --- |
| ![Signin button](img/03_30.png) | ![Open Web UI Consent](img/03_40.png) | ![Signin Page](img/03_50.png)

| Signup flow | Verification Code | Main View |
| --- | --- | --- |
| ![Signup flow](img/03_60.png) | ![Verification Code](img/03_70.png) | ![Main View](img/03_80.png)

[Next](/05_add_api_database.md) : Add API & Database.