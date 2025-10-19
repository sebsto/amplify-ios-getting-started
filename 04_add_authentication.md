# Introduction

The next feature you will be adding is user authentication. In this module, you will learn how to authenticate a user with Amplify Gen2 and libraries, leveraging [Amazon Cognito](https://aws.amazon.com/cognito/), a managed user identity provider.

You will also learn how to use the SwiftUI Authenticator to present an entire user authentication flow, allowing users to sign up, sign in, and reset their password with just a few lines of code.

The SwiftUI Authenticator provides a native iOS user interface that integrates seamlessly with your SwiftUI app, eliminating the need for web redirects while maintaining full customization capabilities.

## What you Will Learn

- Use the authentication service defined in Amplify Gen2
- Configure your iOS app to use SwiftUI Authenticator

## Key Concepts

- Amplify libraries – The Amplify libraries allow you to interact with AWS services from a web or mobile application.

- Authentication – In software, authentication is the process of verifying and managing the identity of a user using an authentication service or API.

# Implementation

## Verify the Authentication Service

The authentication service was already defined in the previous module when we created `amplify/auth/resource.ts`. Let's verify it's configured correctly:

```typescript
// amplify/auth/resource.ts
import { defineAuth } from '@aws-amplify/backend';

export const auth = defineAuth({
  loginWith: {
    email: true,
  },
});
```

This configuration enables email-based authentication with Amazon Cognito. The service is automatically deployed when you run `npx ampx sandbox`.

If your sandbox is not running, start it now:

```zsh
npx ampx sandbox
```

Wait for the deployment to complete and the `amplify_outputs.json` file to be generated.

## Add SwiftUI Authenticator to the Project

We need to add the SwiftUI Authenticator library to our project. In Xcode, select `File > Add Packages...` and add the Authenticator library:

1. Enter the URL: `https://github.com/aws-amplify/amplify-ui-swift-authenticator`
2. Choose **Up to Next Major Version** and click **Add Package**
3. Select **Authenticator** and click **Add Package**

You should now see **Authenticator** as a dependency in your project.

## Update Backend Class for Authentication

The `Backend.swift` file should already be configured with authentication from the previous module. Let's add the authentication methods we'll need.

In `Backend.swift`, add these methods to handle authentication status:

```swift
// Add these methods to the Backend class

public func getInitialAuthStatus() async throws -> AuthStatus {
    // let's check if user is signedIn or not
    let session = try await Amplify.Auth.fetchAuthSession()
    return session.isSignedIn ? AuthStatus.signedIn : AuthStatus.signedOut
}

public func listenAuthUpdate() async -> AsyncStream<AuthStatus> {
    
    return AsyncStream { continuation in
        
        continuation.onTermination = { @Sendable status in
                   print("[BACKEND] streaming auth status terminated with status : \(status)")
        }
        
        // listen to auth events.
        let _  = Amplify.Hub.listen(to: .auth) { payload in
            
            switch payload.eventName {
                
            case HubPayload.EventName.Auth.signedIn:
                print("==HUB== User signed In, update UI")
                continuation.yield(AuthStatus.signedIn)
            case HubPayload.EventName.Auth.signedOut:
                print("==HUB== User signed Out, update UI")
                continuation.yield(AuthStatus.signedOut)
            case HubPayload.EventName.Auth.sessionExpired:
                print("==HUB== Session expired, show sign in aui")
                continuation.yield(AuthStatus.sessionExpired)
            default:
                break
            }
        }
    }
}
```

## Update ViewModel for Authentication

Update your `ViewModel.swift` to handle authentication state:

```swift
// Add these methods to ViewModel class

public func getInitialAuthStatus() async throws {
    
    // when running swift UI preview - do not change isSignedIn flag
    if !EnvironmentVariable.isPreview {
        
        let status = try await Backend.shared.getInitialAuthStatus()
        print("INITIAL AUTH STATUS is \(status)")
        switch status {
        case .signedIn: self.state = .loading
        case .signedOut, .sessionExpired:  self.state = .noData
        }
    }
}

public func listenAuthUpdate() async {
        for try await status in await Backend.shared.listenAuthUpdate() {
            print("AUTH STATUS LOOP yielded \(status)")
            switch status {
            case .signedIn:
                self.state = .loading
            case .signedOut, .sessionExpired:
                self.notes = []
                self.state = .noData
            }
        }
        print("==== EXITED AUTH STATUS LOOP =====")
}
```

Add this helper struct at the bottom of the file:

```swift
struct EnvironmentVariable {
    static var isPreview: Bool {
        return ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
    }
}
```

## Update ContentView with SwiftUI Authenticator

Replace your `ContentView.swift` with this updated version that uses the SwiftUI Authenticator:

```swift
import Authenticator
import SwiftUI

struct ContentView: View {
    @EnvironmentObject public var model: ViewModel
    @State var showCreateNote = false
    
    var body: some View {

        Authenticator { state in
            mainView(state: state)
        }
    }
    
    @ViewBuilder
    func mainView(state: SignedInState) -> some View {
        ZStack {
            switch(model.state) {
                
            case .noData, .loading:
                ProgressView()
                    .task() {
                        await self.model.loadNotes()
                    }
                
            case .dataAvailable(let notes):
                navigationView(notes: notes, signOut: { await state.signOut() } )
                
            case .error(let error):
                Text("There was an error: \(error.localizedDescription)")
            }
            
        }
        .task {
            
            // get the initial authentication status. This call will change app state according to result
            try? await self.model.getInitialAuthStatus()
            
            // start a long polling to listen to auth updates
            await self.model.listenAuthUpdate()
        }
    }
    
    @ViewBuilder
    func navigationView(notes: [Note], signOut: @escaping () async -> Void) -> some View {
        NavigationView {
            List {
                ForEach(notes) { note in
                    ListRow(note: note)
                }
            }
            .navigationTitle(Text("My Memories"))

            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        Task {
                            await signOut()
                        }
                    }) {
                        Text("Sign out")
                    }
                }
            }
        }
    }
}
```

## Build and Test

To verify everything works as expected, build the project. Click **Product** menu and select **Run** or type **⌘R**. 

The app will now show the SwiftUI Authenticator interface when you're not signed in, providing a native iOS authentication experience with sign up, sign in, and password reset capabilities.

The SwiftUI Authenticator provides a complete authentication flow with:
- Native iOS interface
- Sign up with email verification
- Sign in with email and password
- Password reset functionality
- Automatic session management

[Next](/05_add_api_database.md) : Add API & Database.