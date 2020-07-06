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
