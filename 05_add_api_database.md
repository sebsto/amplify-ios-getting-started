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
