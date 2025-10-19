# Introduction

Now that we have the notes app working, let's add the ability to associate an image with each note. In this module, you will use the existing Amplify Gen2 storage service leveraging [Amazon S3](https://aws.amazon.com/s3/). The storage service is already configured and the iOS app already includes image uploading, fetching, and rendering capabilities.

## What You Will Learn

- Create a storage service
- Update your iOS app - the logic to upload and download images
- Update your iOS app - the user interface

## Key Concepts

Storage service - Storing and querying for files like images and videos is a common requirement for most applications. One option to do this is to Base64 encode the file and send as a string to save in the database. This comes with disadvantages like the encoded file being larger than the original binary, the operation being computationally expensive, and the added complexity around encoding and decoding properly. Another option is to have a storage service specifically built and optimized for file storage. Storage services like Amazon S3 exist to make this as easy, performant, and inexpensive as possible.

# Implementation

## Verify the Storage Service

The storage service was already defined in the previous modules when we created `amplify/storage/resource.ts`. Let's verify it's configured correctly:

```typescript
// amplify/storage/resource.ts
import { defineStorage } from '@aws-amplify/backend';

export const storage = defineStorage({
  name: 'image',
  access: (allow) => ({
    'private/{entity_id}/*': [
      allow.entity('identity').to(['read', 'write', 'delete'])
    ],
  })
});
```

This configuration:
- Creates an S3 bucket named 'image'
- Allows authenticated users to read, write, and delete their own files
- Uses private access level (files are isolated per user)
- Files are stored under `private/{entity_id}/` path structure

## Verify Storage Deployment

The storage service is automatically deployed with your sandbox. If your sandbox is not running, start it:

```zsh
npx ampx sandbox
```

The S3 bucket and necessary IAM permissions are created automatically.

## Verify Storage Plugin Installation

The **AWSS3StoragePlugin** should already be installed from the previous modules. Verify it's included in your `Backend.swift` initialization:

```swift
try Amplify.add(plugin: AWSS3StoragePlugin())
```

## Verify Backend Storage Initialization

Your `Backend.swift` should already include the storage plugin from previous modules. The initialization should look like this:

```swift
import AWSS3StoragePlugin

// In the Backend init method:
try Amplify.add(plugin: AWSS3StoragePlugin())
try Amplify.configure(with: .amplifyOutputs)
```

## Verify Image Storage Methods

The `Backend.swift` file already includes the necessary storage methods using modern async/await patterns:

```swift
// MARK: Image Access
func storagePath(for key:String) async -> IdentityIDStoragePath {
    await withCheckedContinuation { continuation in
       let storagePath = IdentityIDStoragePath.fromIdentityID { identityId in
            return "private/\(identityId)/\(key)"
        }
        continuation.resume(returning: storagePath)
    }
}

func storeImage(name: String, image: Data) async {
    
    do {
        let path = await storagePath(for: name)
        let task = Amplify.Storage.uploadData(path: path, data: image)
        let result = try await task.value
        print("Image upload completed: \(result)")

    } catch let error as StorageError {
        print("Can not upload image \(name): \(error.errorDescription). \(error.recoverySuggestion)")
    } catch {
        print("Unknown error when uploading image \(name): \(error)")
    }
}

func imageURL(name: String) async -> URL? {
    
    var result: URL? = nil
    do {
        let path = await storagePath(for: name)
        result = try await Amplify.Storage.getURL(path: path)

    } catch let error as StorageError {
        print("Can not retrieve URL for image \(name): \(error.errorDescription). \(error.recoverySuggestion)")
    } catch {
        print("Unknown error when retrieving URL for image \(name): \(error)")
    }
    return result
}

func deleteImage(name: String) async {
    
    do {
        let path = await storagePath(for: name)
        let result = try await Amplify.Storage.remove(path: path)
        print("Image \(name) deleted (result: \(result)")
    } catch let error as StorageError {
        print("Can not delete image \(name): \(error.errorDescription). \(error.recoverySuggestion)")
    } catch {
        print("Unknown error when deleting image \(name): \(error)")
    }
}
```

These methods use:
- **Modern async/await** patterns instead of callbacks
- **IdentityIDStoragePath** for user-specific file paths
- **Private access level** - files are only accessible by their owner
- **Proper error handling** with StorageError types

## Verify Image Loading in Note Model

The `Note` class in `Model.swift` already includes image loading functionality:

```swift
// In the Note class
@MainActor @Published var imageURL : URL?

// In the convenience init(from data: NoteData) method:
if let name = self.imageName {
    
    // asynchronously generate the URL of the image.
    Task { @MainActor () -> Void in
        if self.imageURL == nil {
            print("requesting image URL")
            self.imageURL = await Backend.shared.imageURL(name: name)
            print("received image URL")
        }
    }
}
```

This approach:
- Uses **AsyncImage** in SwiftUI instead of manual image loading
- Generates **signed URLs** for secure image access
- Uses **@MainActor** to ensure UI updates happen on the main thread
- Leverages **Task** for modern Swift concurrency

## Verify Image Capture UI

The `CaptureImageView.swift` file should already exist in your project with the image picker functionality. This file provides:

- **UIImagePickerController** integration with SwiftUI
- **Photo library access** for selecting images
- **Camera support** (on real devices)
- **Coordinator pattern** for UIKit/SwiftUI bridging

The implementation uses `UIViewControllerRepresentable` to wrap the UIKit image picker in a SwiftUI-compatible view.

## Verify Image Storage in AddNoteView

The `AddNoteView` in `ContentView.swift` already includes image capture and storage functionality:

```swift
struct AddNoteView: View {
    @Binding var isPresented: Bool
    var model: ViewModel

    @State var name : String        = "New memory"
    @State var description : String = "These are my notes from this moment"
    @State var image : UIImage?
    @State var showCaptureImageView = false

    // PICTURE section with image picker
    Section(header: Text("PICTURE")) {
        VStack {
            Button(action: {
              self.showCaptureImageView.toggle()
            }) {
              Text("Choose photo")
            }.sheet(isPresented: $showCaptureImageView) {
                CaptureImageView(isShown: self.$showCaptureImageView, image: self.$image)
            }
            if (image != nil ) {
                HStack {
                    Spacer()
                    Image(uiImage: image!)
                        .resizable()
                        .frame(width: 250, height: 200)
                        .clipShape(Circle())
                    Spacer()
                    }
            }
        }
    }

    // Create button that handles image upload
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
```

The image upload is handled in the `ViewModel.addNote` method:

```swift
// In ViewModel.swift
func addNote(name: String, description: String?, image: UIImage?) async {
    let note = Note(id : UUID().uuidString,
                    name: name,
                    description: description,
                    createdAt: Date.now)

    // Handle image upload if provided
    if let i = image  {
        let smallImage = i.resize(to: 0.05)
        note.imageName = UUID().uuidString

        Task {
            // asynchronously store the image
            await Backend.shared.storeImage(name: note.imageName!, image: (smallImage.pngData())!)
            
            // asynchronously generate the URL of the image
            note.imageURL = await Backend.shared.imageURL(name: note.imageName!)
        }
    }
    
    // Store the note
    Task {
        await Backend.shared.createNote(note: note)
    }
    
    self.notes.append(note)
    self.state = .dataAvailable(self.notes)
}
```

## Build and Test

To verify everything works as expected, build and run the project. Click **Product** menu and select **Run** or type **&#8984;R**. There should be no error.

Assuming you are still signed in, the app starts on the list with one Note.  Use the `+` sign again to create a Note. This time, add a picture selected from the local image store.

Here is the complete flow.

| One Note in the List | Create a Note | Pick Image 1 | Pick Image 2 | Note with Image
| --- | --- | --- | -- | -- | 
| ![One Note in the List](img/06_10.png) | ![Create a Note](img/06_20.png) | ![Pick Image 1](img/06_30.png) | ![Pick Image 2](img/06_40.png) | ![Note with Image](img/06_50.png)

## Congratulations 🥁🏆🎊🎉🎈 !

You have build an iOS application using AWS Amplify! You have added authentication to your app allowing users to sign up, sign in, and manage their account. The app also has a scalable GraphQL API configured with an Amazon DynamoDB database allowing users to create and delete notes. You have also added file storage using Amazon S3 allowing users to upload images and view them in their app.

In the last section, you will find instructions to reuse or to delete the backend we just created.

[Next](/07_cleanup.md) : Cleanup.