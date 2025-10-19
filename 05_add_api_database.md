# Introduction

Now that we've created and configured the app with user authentication, let's add an API and Create, Read, Update, Delete (CRUD) operations on a database.

In this module, you will add an API to our app using Amplify Gen2 and libraries. The API you will be creating is a [GraphQL](https://graphql.org) API that leverages [AWS AppSync](https://aws.amazon.com/appsync/) (a managed GraphQL service) which is backed by [Amazon DynamoDB](https://aws.amazon.com/dynamodb/) (a NoSQL database). For an introduction to GraphQL, [visit this page](https://graphql.org/learn/).

The app we will be building is a note taking app that allows users to create, delete, and list notes. This example gives you a good idea how to build many popular types of CRUD+L (create, read, update, delete, and list) applications.

## What You Will Learn

- Create and deploy a GraphQL API
- Write front-end code to interact with the API

## Key Concepts

**API** – Provides a programming interface that allows communication and interactions between multiple software intermediaries.

**GraphQL** – A query language and server-side API implementation based on a typed representation of your application. This API representation is declared using a schema based on the GraphQL type system. (To learn more about GraphQL, [visit this page](https://graphql.org/learn/).)

# Implementation

## Verify the GraphQL API and Database

The GraphQL API and database were already defined in the previous modules when we created `amplify/data/resource.ts`. Let's verify the schema is correct:

```typescript
// amplify/data/resource.ts
import { type ClientSchema, a, defineData } from '@aws-amplify/backend';

const schema = a.schema({
  NoteData: a
    .model({
      id: a.id(),
      name: a.string().required(),
      description: a.string(),
      image: a.string(),
    })
    .authorization((allow) => [allow.owner()]),
});

export type Schema = ClientSchema<typeof schema>;

export const data = defineData({
  schema,
  authorizationModes: {
    defaultAuthorizationMode: 'userPool',
  },
});
```

This schema defines:
- A `NoteData` model with `id` and `name` as required fields
- Optional `description` and `image` fields
- Owner-based authorization (only the creator can access their notes)
- User pool authentication as the default authorization mode

The API and database are automatically deployed when you run `npx ampx sandbox`.

## Add Generated Model Files to Xcode

Amplify Gen2 automatically generates Swift model files when you run the sandbox. These files should already be present in your project root directory:

- `AmplifyModels.swift`
- `NoteData.swift` 
- `NoteData+Schema.swift`

If they're not already in your Xcode project, **locate** them in the Finder and **drag and drop them** into your Xcode project.

![Insert generated files in the project](img/05_10.gif)

## Verify API Deployment

The API and database are automatically deployed with your sandbox. If your sandbox is not running, start it:

```zsh
npx ampx sandbox
```

You should see output indicating the GraphQL API endpoint is available.

## Verify API Plugin Installation

The **AWSAPIPlugin** should already be installed from the previous modules. Verify it's included in your `Backend.swift` initialization:

```swift
try Amplify.add(plugin: AWSAPIPlugin(modelRegistration: AmplifyModels()))
```

## Verify Backend Initialization

Your `Backend.swift` should already be properly configured from previous modules. Verify it includes the API plugin:

```swift
import AWSAPIPlugin

// In the Backend init method:
try Amplify.add(plugin: AWSAPIPlugin(modelRegistration: AmplifyModels()))
```

## Verify Model Bridging

The `Note` class in `Model.swift` already includes the necessary bridging between the GraphQL `NoteData` and our app model:

```swift
// convert from backend data struct to our model
convenience init(from data: NoteData) {
    self.init(id: data.id,
              name: data.name,
              description: data.description,
              image: data.image,
              createdAt: data.createdAt?.foundationDate)
    
    // Handle image URL loading if needed
    if let name = self.imageName {
        Task { @MainActor () -> Void in
            if self.imageURL == nil {
                self.imageURL = await Backend.shared.imageURL(name: name)
            }
        }
    }
}

// convert our model to backend data format
var data: NoteData {
    get {
        return NoteData(id: self.id,
                        name: self.name,
                        description: self.description,
                        image: self.imageName,
                        createdAt: .init(self.createdAt ?? Date.now))
    }
}
```

## Verify API Methods in Backend Class

The `Backend.swift` file already includes the necessary API methods using modern async/await patterns:

```swift
// MARK: API Access

func queryNotes() async -> [ Note ] {
    
    do {
        print("Loading notes")
        let queryResult = try await Amplify.API.query(request: .list(NoteData.self))
        print("Successfully retrieved list of Notes")
        
        // convert [ NoteData ] to [ Note ]
        let result = try queryResult.get().map { noteData in
            Note.init(from: noteData)
        }
        
        // Sort by creation date (newest first)
        return result.sorted { lhs, rhs in
            if let ldate = lhs.createdAt, let rdate = rhs.createdAt {
                return ldate > rdate
            } else {
                return false
            }
        }
        
    } catch let error as APIError {
        print("Failed to load data from api : \(error)")
    } catch {
        print("Unexpected error while calling API : \(error)")
    }
    
    return []
}

func createNote(note: Note) async {
    
    do {
        let result = try await Amplify.API.mutate(request: .create(note.data))
        let data = try result.get()
        print("Successfully created note: \(data)")
    } catch let error as APIError {
        print("Failed to create note: \(error)")
    } catch {
        print("Unexpected error while calling create API : \(error)")
    }
}

func deleteNote(note: Note) async {
    
    do {
        let result = try await Amplify.API.mutate(request: .delete(note.data))
        let data = try result.get()
        print("Successfully deleted note: \(data)")
        
    } catch let error as APIError {
        print("Failed to delete note: \(error)")
    } catch {
        print("Unexpected error while calling delete API : \(error)")
    }
}
```

These methods use modern Swift concurrency (async/await) and proper error handling.

## Verify ViewModel Integration

The `ViewModel.swift` file already includes methods to integrate with the Backend API:

```swift
// load notes from the backend
@discardableResult
func loadNotes() async -> [Note] {
    if self.notes.isEmpty {
        self.notes = await Backend.shared.queryNotes()
    }
    self.state = .dataAvailable(self.notes)
    return self.notes
}

// add a note to the model and the backend 
func addNote(name: String, description: String?, image: UIImage?) async {
    let note = Note(id : UUID().uuidString,
                    name: name,
                    description: description,
                    createdAt: Date.now)

    // asynchronously store the note
    Task {
        await Backend.shared.createNote(note: note)
    }
    
    // Handle image upload if provided
    if let i = image  {
        // Image handling code...
    }
    
    self.notes.append(note)
    self.state = .dataAvailable(self.notes)
}

// delete a note from the model and the backend
func deleteNote(at: Int) {
    let note = self.notes.remove(at: at)
    
    Task {
        await Backend.shared.deleteNote(note: note)
        
        if let n = note.imageName {
            await Backend.shared.deleteImage(name: n)
        }
    }
}
```

## Verify UI Components

The `ContentView.swift` already includes the necessary UI components for creating and managing notes:

1. **Add Note Button**: The navigation view includes a `+` button in the toolbar:

    ```swift
    .toolbar {
        ToolbarItem(placement: .navigationBarTrailing) {
            Button(action: {
                self.showCreateNote.toggle()
            }) {
                Image(systemName: "plus")
            }
        }
    }
    .sheet(isPresented: $showCreateNote) {
        AddNoteView(isPresented: self.$showCreateNote, model: self.model)
    }
    ```

2. **Add Note View**: The `AddNoteView` struct handles note creation:

    ```swift
    struct AddNoteView: View {
        @Binding var isPresented: Bool
        var model: ViewModel

        @State var name : String        = "New memory"
        @State var description : String = "These are my notes from this moment"
        @State var image : UIImage?
        @State var showCaptureImageView = false

        var body: some View {
            Form {
            
                Section(header: Text("TEXT")) {
                    TextField("Name", text: $name)
                    TextField("Description", text: $description)
                }
                
                Section(header: Text("PICTURE")) {
                    VStack {
                        Button(action: {
                          self.showCaptureImageView.toggle()
                        }) {
                          Text("Choose photo")
                        }.sheet(isPresented: $showCaptureImageView) {
                            CaptureImageView(isShown: self.$showCaptureImageView, image: self.$image)
                        }
                        // Image preview code...
                    }
                }

                Section {
                    Button(action: {
                        self.isPresented = false
                        
                        withAnimation {
                            let _ = Task { await self.model.addNote(name: self.name,
                                                                    description: self.description,
                                                                    image: self.image)
                            }
                        }
                    }) {
                        Text("Create this memory")
                    }
                }
            }
        }
    }
    ```

## Verify Swipe to Delete

The swipe-to-delete functionality is already implemented in the `ContentView`:

```swift
List {
    ForEach(notes) { note in
        ListRow(note: note)
    }.onDelete { indices in
        indices.forEach {
            self.model.deleteNote(at: $0)
        }
    }
}
```

This calls the `deleteNote` method in the ViewModel, which handles both removing the note from the local array and deleting it from the backend API.

## Build and Test

To verify everything works as expected, build and run the project. Click **Product** menu and select **Run** or type **&#8984;R**. There should be no error.

Assuming you are still signed in, the app starts on the emply List. It now has a `+` button to add a Note.  **Tap the + sign**, **Tap Create this Note** and the note should appear in the list.

You can close the `AddNoteView` by pulling it down.  Note that, on the iOS simulator, it is not possible to tap `+` a second time, you need to 'pull-to-refresh' the List first.

You can delete Note by swiping a row left.

Here is the complete flow.

| Empty List | Create a Note | One Note in the List | Delete a Note |
| --- | --- | --- | --- |
| ![Empty List](img/05_20.png) | ![Create Note](img/05_30.png) | ![One Note in the List](img/05_40.png) | ![Delete a Note ](img/05_50.png) |

In the next section, we will add UI and behavior to manage pictures.

[Next](/06_add_storage.md) : Add file storage.