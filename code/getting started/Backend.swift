import SwiftUI
import Amplify
import AWSCognitoAuthPlugin
import AWSAPIPlugin
import AWSS3StoragePlugin

class Backend  {
    
    static let shared = Backend()
    
    private init() {
        // initialize amplify
        do {
//            Amplify.Logging.logLevewl = .info

            try Amplify.add(plugin: AWSCognitoAuthPlugin())
            try Amplify.add(plugin: AWSAPIPlugin(modelRegistration: AmplifyModels()))
            try Amplify.add(plugin: AWSS3StoragePlugin())
            
            try Amplify.configure()
            print("Initialized Amplify")
        } catch {
            print("Could not initialize Amplify: \(error)")
        }
        
        // asynchronously
        Task {
            // let's check if user is signedIn or not
            let session = try await Amplify.Auth.fetchAuthSession()
            
            // let's update UserData and the UI
            await self.updateUserData(withSignInStatus: session.isSignedIn)
        }
        
        // listen to auth events.
        // see https://github.com/aws-amplify/amplify-ios/blob/master/Amplify/Categories/Auth/Models/AuthEventName.swift
        let _  = Amplify.Hub.listen(to: .auth) { payload in
            
            switch payload.eventName {
                
            case HubPayload.EventName.Auth.signedIn:
                Task {
                    print("==HUB== User signed In, update UI")
                    await self.updateUserData(withSignInStatus: true)
                }
            case HubPayload.EventName.Auth.signedOut:
                Task {
                    print("==HUB== User signed Out, update UI")
                    await self.updateUserData(withSignInStatus: false)
                }
            case HubPayload.EventName.Auth.sessionExpired:
                Task {
                    print("==HUB== Session expired, show sign in aui")
                    await self.updateUserData(withSignInStatus: false)
                }
            default:
                //print("==HUB== \(payload)")
                break
            }
        }
    }
    
    // MARK: Authentication
    // change our internal state, this triggers an UI update on the main thread
    @MainActor
    func updateUserData(withSignInStatus status : Bool) async {
        let userData : UserData = .shared
        userData.isSignedIn = status
        
        // when user is signed in, query the database, otherwise empty our model
        if (status && userData.notes.isEmpty) {
            userData.notes = await self.queryNotes()
        } else {
            userData.notes = []
        }
    }
    
    @MainActor
    private func anchorWindow() async -> UIWindow {
        // UIApplication.shared.windows.first is deprecated on iOS 15
        // solution from https://stackoverflow.com/questions/57134259/how-to-resolve-keywindow-was-deprecated-in-ios-13-0/57899013
        
        let w = UIApplication
            .shared
            .connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }
        
        return w!
    }
    
    public func signIn() async {
        
        do {
            let window = await self.anchorWindow()
            let result = try await Amplify.Auth.signInWithWebUI(presentationAnchor: window)
            if (result.isSignedIn) {
                print("Sign in succeeded")
            } else {
                print("Signin failed or required a next step")
            }
        } catch {
            print("Error while presenting web ui : \(error)")
        }
    }
    
    // signout
    public func signOut() async {
        
        let _ =  await Amplify.Auth.signOut()
    }
    
    // MARK: API Access
    
    func queryNotes() async -> [ Note ] {
        
        do {
            let queryResult = try await Amplify.API.query(request: .list(NoteData.self))
            print("Successfully retrieved list of Notes")
            
            // convert [ NoteData ] to [ Note ]
            let result = try queryResult.get().map { noteData in
                Note.init(from: noteData)
            }
            
            return result
            
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
    
    // MARK: Image Access
    
    func storeImage(name: String, image: Data) async {
        
        do {
            let options = StorageUploadDataRequest.Options(accessLevel: .private)
            let task = try await Amplify.Storage.uploadData(key: name, data: image, options: options)
            let result = try await task.value
            print("Image upload completed: \(result)")

        } catch let error as StorageError {
            print("Can not upload image \(name): \(error.errorDescription). \(error.recoverySuggestion)")
        } catch {
            print("Unknown error when uploading image \(name): \(error)")
        }
    }
    
    func retrieveImage(name: String) async -> Data {
        
        do {
            let options = StorageDownloadDataRequest.Options(accessLevel: .private)
            let task = try await Amplify.Storage.downloadData(key: name, options: options)
            let data = try await task.value
            print("Successfully downloaded image: \(data)")

            return data
            
        } catch let error as StorageError {
            print("Can not retrieve image \(name): \(error.errorDescription). \(error.recoverySuggestion)")
        } catch {
            print("Unknown error when retrieving image \(name): \(error)")
        }
        return Data() // could return a default image

    }
    
    func deleteImage(name: String) async {
        
        do {
            let options = StorageRemoveRequest.Options(accessLevel: .private)
            let result = try await Amplify.Storage.remove(key: name, options: options)
            print("Image \(name) deleted (result: \(result)")
        } catch let error as StorageError {
            print("Can not delete image \(name): \(error.errorDescription). \(error.recoverySuggestion)")
        } catch {
            print("Unknown error when deleting image \(name): \(error)")
        }
    }
}
