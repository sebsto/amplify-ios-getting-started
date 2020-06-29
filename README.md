iOS Getting Started, following the same structure as
https://aws.amazon.com/getting-started/learning-path-front-end-developer/

# Introduction

# Create an iOS App

add step by step project creation guide with Xcode screenshots

## Update the main view

Open `ContentView.swift` and replace the code with this content:

```swift
import SwiftUI

// singleton object to store user data
class UserData : ObservableObject {
    private init() {}
    static let shared = UserData()

    @Published var notes : [Note] = []
    @Published var isSignedIn : Bool = false
}

class Note : Identifiable, ObservableObject {
    var id : String
    var name : String
    var description : String?
    var imageName : String?

    init(id: String, name: String) {
        self.id = id
        self.name = name
    }
}

struct ListRow: View {
    @ObservedObject var note : Note
    var body: some View {

        return HStack(alignment: .center, spacing: 5.0) {

            if ((note.imageName) != nil) {
                Image(systemName: note.imageName!)
                .resizable()
                .frame(width: 50, height: 50)
                .padding()
            }

            VStack(alignment: .leading, spacing: 5.0) {
                Text(note.name)
                .bold()

                if ((note.description) != nil) {
                    Text(note.description!)
                }
            }
        }
    }
}

struct ContentView: View {
    @ObservedObject private var userData: UserData = .shared

    var body: some View {
        List {
            ForEach(userData.notes) { note in
                ListRow(note: note)
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {

        let _ = prepareTestData()

        return ContentView()
    }
}

func prepareTestData() -> UserData {
    let userData = UserData.shared
    userData.isSignedIn = true
    let desc = "this is a very long description that should fit on multiiple lines.\nit even has a line break\nor two."

    let n1 = Note(id: "01", name: "Hello world")
    let n2 = Note(id: "02", name: "A new note")
    userData.notes = [ n1, n2 ]
    n1.description = desc
    n2.description = desc
    n1.imageName = "mic"
    n2.imageName = "phone"
    return userData
}

```

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

# Add an API & database

## Create the Schema

```GraphQL
type NoteData
  @model
  @auth (rules: [ { allow: owner } ]) {
    id: ID!
    name: String!
    description: String
    image: String
}
```

## Create the API service and database  

```zsh
amplify update api

# update auth setting : Cognito
```

## Generate client side code

modelgen=true
Build
modelgen=false

Check AmplifyModels has been added to XCode project.

## Deploy the API service and database

push=true
Build
push=false


## Add client library to the Xcode project

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
  pod 'AmplifyPlugins/AWSAPIPlugin', '~> 1.0'         # support for GraphQL API

end
```

```zsh
pod install
```

## Initialize Amplify Libs at Runtime

Open `Backend` and add this line in the Amplify initialisation sequence in `private init()`

```Swift
// initialize amplify
do {
   try Amplify.add(plugin: AWSCognitoAuthPlugin())
   try Amplify.add(plugin: AWSAPIPlugin(modelRegistration: AmplifyModels()))
   try Amplify.configure()
   print("Initialized Amplify");
} catch {
   print("Could not initialize Amplify: \(error)")
}
```

## Add bridging between GraphQL data model and app model

Open `ContentView.swift` and add this initializer in the `Note` class

```swift
init(from: NoteData) {
    self.id          = from.id
    self.name        = from.name
    self.description = from.description
    self.imageName   = from.image
}
```

## Add API query method to the `Backend`

```swift
// MARK: API Access

func queryNotes() {

    _ = Amplify.API.query(request: .list(NoteData.self)) { event in
        switch event {
        case .success(let result):
            switch result {
            case .success(let notesData):
                print("Successfully retrieved list of Notes")

                for n in notesData {
                    let note = Note.init(from: n)
                    DispatchQueue.main.async() {
                        UserData.shared.notes.append(note);
                    }
                }

            case .failure(let error):
                print("Can not retrieve result : error  \(error.errorDescription)")
            }
        case .failure(let error):
            print("Can not retrieve Notes : error \(error)")
        }
    }
}
```

At start of application, let's verify if user is signed in or not. When user is signed in, let's call the API.  Add this piece of code in the `Backend`'s `private init()` method:

```swift
// let's check if user is signedIn or not
_ = Amplify.Auth.fetchAuthSession { (result) in

    do {
        let session = try result.get()

        // let's update UserData and the UI
        self.updateUI(forSignInStatus: session.isSignedIn)

        // when user is signed in, query the database
        if session.isSignedIn {
            self.queryNotes()
        }
    } catch {
        print("Fetch auth session failed with error - \(error)")
    }

}
```
## Add an Edit Button to Add Note

In `ContentView`

1. Add

```swift
@State var showCreateNote = false

@State var name : String        = "New Note"
@State var description : String = "This is a new note"
@State var image : String       = "image"
```

2. Add a + button on the navigation bar to present a sheet to add a Note

```Swift
.navigationBarItems(leading: SignOutButton(), trailing: Button(action: {
    self.showCreateNote.toggle()
}) {
    Image(systemName: "plus")
})
}.sheet(isPresented: $showCreateNote) {
AddNoteView(isPresented: self.$showCreateNote, userData: self.userData)
}
```

3.  Define a View to add a Note

```swift
struct AddNoteView: View {
    @Binding var isPresented: Bool
    var userData: UserData

    @State var name : String        = "New Note"
    @State var description : String = "This is a new note"
    @State var image : String       = "image"
    var body: some View {
        Form {

            Section(header: Text("TEXTE")) {
                TextField("Name", text: $name)
                TextField("Name", text: $description)
            }

            Section(header: Text("PICTURE")) {
                TextField("Name", text: $image)
            }

            Section {
                Button(action: {
                    self.isPresented = false
                    let noteData = NoteData(id : UUID().uuidString,
                                            name: self.$name.wrappedValue,
                                            description: self.$description.wrappedValue)
                    let note = Note(from: noteData)

                    // asynchronously store the note (and assume it will succeed)
                    Backend.shared.createNote(note: note)

                    // add the new note in our userdata, this will refresh UI
                    self.userData.notes.append(note)
                }) {
                    Text("Create this note")
                }
            }
        }
    }
}
```

In `Backend`, add a GraphQL mutation to add a note :

```Swift
func createNote(note: Note) {
    guard let data = note.data else {
        assertionFailure("Note object contains no NoteData reference")
        return
    }

    _ = Amplify.API.mutate(request: .create(data)) { event in
        switch event {
        case .success(let result):
            switch result {
            case .success(let data):
                print("Successfully created note: \(data)")
            case .failure(let error):
                print("Got failed result with \(error.errorDescription)")
            }
        case .failure(let error):
            print("Got failed event with error \(error)")
        }
    }
}
```

## Add a Swipe to Delete Behaviour

In `ContentView`, add the swipe to delete behaviour

```swift
ForEach(userData.notes) { note in
    ListRow(note: note)
}.onDelete() { (indexSet) in
    // we might receive multiple indexes when view is in edit mode
    let indexes = Array(indexSet)
    for i in indexes {
        // removing from user data will refresh UI
        let note = self.userData.notes.remove(at: indexes[i-1])
        // asynchronously remove from database, and assume it will succeed
        Backend.shared.deleteNote(note: note)
    }
}
```

In `Backend`, add a GraphQL mutation to delete a note

```swift
    func deleteNote(note: Note) {
        guard let data = note.data else {
            assertionFailure("Note object contains no NoteData reference")
            return
        }

        _ = Amplify.API.mutate(request: .delete(data)) { event in
            switch event {
            case .success(let result):
                switch result {
                case .success(let data):
                    print("Successfully deleted note: \(data)")
                case .failure(let error):
                    print("Got failed result with \(error.errorDescription)")
                }
            case .failure(let error):
                print("Got failed event with error \(error)")
            }
        }
    }
  ```

# Add Storage

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
  pod 'AmplifyPlugins/AWSAPIPlugin', '~> 1.0'         # support for GraphQL API
  pod 'AmplifyPlugins/AWSS3StoragePlugin', '~> 1.0'   # support for Amazon S3 storage

end
```

## Create the Storage Service

```zsh
amplify add storage
? Please select from one of the below mentioned services: Content (Images, audio, video, etc.)
? Please provide a friendly name for your resource that will be used to label this category in the project: images
? Please provide bucket name: codee7f7696fb8384e7e97bd12cb4d606c7e
? Who should have access: Auth users only
? What kind of access do you want for Authenticated users? create/update, read, delete
? Do you want to add a Lambda Trigger for your S3 Bucket? No
Successfully added resource images locally
```

## Deploy the Storage Service

``` zsh
➜  code git:(master) ✗ amplify push
✔ Successfully pulled backend environment amplify from the cloud.

Current Environment: amplify

| Category | Resource name | Operation | Provider plugin   |
| -------- | ------------- | --------- | ----------------- |
| Storage  | images        | Create    | awscloudformation |
| Api      | code          | No Change | awscloudformation |
| Auth     | code40a20d41  | No Change | awscloudformation |
? Are you sure you want to continue? Yes
⠋ Updating resources in the cloud. This may take a few minutes...
```

## Add UI code to capture an image

Create a `CaptureImageView.swift` file with:

```swift
import Foundation
import UIKit
import SwiftUI

struct CaptureImageView {

  /// MARK: - Properties
  @Binding var isShown: Bool
  @Binding var image: UIImage?

  func makeCoordinator() -> Coordinator {
    return Coordinator(isShown: $isShown, image: $image)
  }
}

class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
  @Binding var isCoordinatorShown: Bool
  @Binding var imageInCoordinator: UIImage?
  init(isShown: Binding<Bool>, image: Binding<UIImage?>) {
    _isCoordinatorShown = isShown
    _imageInCoordinator = image
  }
  func imagePickerController(_ picker: UIImagePickerController,
                didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
     guard let unwrapImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage else { return }
     imageInCoordinator = unwrapImage
     isCoordinatorShown = false
  }
  func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
     isCoordinatorShown = false
  }
}

extension CaptureImageView: UIViewControllerRepresentable {
    func makeUIViewController(context: UIViewControllerRepresentableContext<CaptureImageView>) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController,
                                context: UIViewControllerRepresentableContext<CaptureImageView>) {

    }
}
```

## Initialize Amplify Storage plugin at runtime

In the initializer of `Backend`, add the Storage plugin.

```swift
// initialize amplify
do {
   try Amplify.add(plugin: AWSCognitoAuthPlugin())
   try Amplify.add(plugin: AWSAPIPlugin(modelRegistration: AmplifyModels()))
   try Amplify.add(plugin: AWSS3StoragePlugin())
   try Amplify.configure()
   print("Initialized Amplify");
} catch {
   print("Could not initialize Amplify: \(error)")
}
```

## Add Image CRUD methods to the `Backend`

```Swift
func storeImage(name: String, image: Data) {

//        let options = StorageUploadDataRequest.Options(accessLevel: .private)
    let _ = Amplify.Storage.uploadData(key: name, data: image,// options: options,
        progressListener: { progress in
            // optionlly update a progress bar here
        }, resultListener: { event in
            switch event {
            case .success(let data):
                print("Image upload completed: \(data)")
            case .failure(let storageError):
                print("Image upload failed: \(storageError.errorDescription). \(storageError.recoverySuggestion)")
        }
    })
}

func retrieveImage(name: String, completed: @escaping (Data) -> Void) {
    let _ = Amplify.Storage.downloadData(key: name,
        progressListener: { progress in
            // in case you want to monitor progress
        }, resultListener: { (event) in
            switch event {
            case let .success(data):
                print("Image \(name) loaded")
                completed(data)
            case let .failure(storageError):
                print("Can not download image: \(storageError.errorDescription). \(storageError.recoverySuggestion)")
            }
        }
    )
}

func deleteImage(name: String) {
    let _ = Amplify.Storage.remove(key: name,
        resultListener: { (event) in
            switch event {
            case let .success(data):
                print("Image \(data) deleted")
            case let .failure(storageError):
                print("Can not delete image: \(storageError.errorDescription). \(storageError.recoverySuggestion)")
            }
        }
    )
}
```

## Load image when data are retrieved from the API

Open `ContentView.swift` and update the `Note`'s initializer:

```swift
// add a publishable's object property
@Published var image : Image?

// update init's code
init(from: NoteData) {
    self.id          = from.id
    self.name        = from.name
    self.description = from.description
    self.imageName   = from.image

    if let name = self.imageName {
        // asynchronously download the image
        Backend.shared.retrieveImage(name: name) { (data) in
            // update the UI on the main thread
            DispatchQueue.main.async() {
                let uim = UIImage(data: data)
                self.image = Image(uiImage: uim!)
            }
        }
    }
    // store API object for easy retrieval later
    self.data = from
}
```

## Store image when Notes are created

Modify the `AddNoteView` (in `ContentView.swift)`) to add an ImagePicker component:

```swift
// at the start of the class
@State var image : UIImage?
@State var showCaptureImageView = false

// in the view
Section(header: Text("PICTURE")) {
    VStack {
        Button(action: {
          self.showCaptureImageView.toggle()
        }) {
          Text("Choose photo")
        }.sheet(isPresented: $showCaptureImageView) {
            CaptureImageView(isShown: self.$showCaptureImageView, image: self.$image)
        }
        HStack {
            Spacer()
            Image(uiImage: image!)
                .resizable()
                .frame(width: 250, height: 200)
                .clipShape(Circle())
                .overlay(Circle().stroke(Color.white, lineWidth: 4))
                .shadow(radius: 10)
            Spacer()
        }
    }
}
```

Modify the `Create Note` section to store the image as well as the Note :

```swift
Section {
    Button(action: {
        self.isPresented = false

        let imageName = UUID().uuidString

        let noteData = NoteData(id : UUID().uuidString,
                                name: self.$name.wrappedValue,
                                description: self.$description.wrappedValue,
                                image: imageName)

        let note = Note(from: noteData)  

        if let i = self.image  {
            // asynchronously store the image (and assume it will work)
            Backend.shared.storeImage(name: imageName, image: (i.pngData())!)
            note.image = Image(uiImage: i)
        }

        // asynchronously store the note (and assume it will succeed)
        Backend.shared.createNote(note: note)

        // add the new note in our userdata, this will refresh UI
        self.userData.notes.append(note)
    }) {
        Text("Create this note")
    }
}
```
