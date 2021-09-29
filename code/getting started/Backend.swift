import Foundation
import Amplify
import AmplifyPlugins

class Backend  {
    
    static let shared = Backend()
    
    @discardableResult
    static func initialize() -> Backend {
        return .shared
    }
    private init() {
        // initialize amplify
        do {
           try Amplify.add(plugin: AWSCognitoAuthPlugin())
           try Amplify.add(plugin: AWSAPIPlugin(modelRegistration: AmplifyModels()))
           try Amplify.add(plugin: AWSS3StoragePlugin())
            
           try Amplify.configure()
           print("Initialized Amplify")
        } catch {
           print("Could not initialize Amplify: \(error)")
        }
        
        // let's check if user is signedIn or not
        Amplify.Auth.fetchAuthSession { (result) in

            do {
                let session = try result.get()
                
                // let's update UserData and the UI
                self.updateUserData(withSignInStatus: session.isSignedIn)
                
            } catch {
                print("Fetch auth session failed with error - \(error)")
            }

        }
        
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
                print("==HUB== Session expired, show sign in aui")
                self.updateUserData(withSignInStatus: false)

            default:
                //print("==HUB== \(payload)")
                break
            }
        }
    }
    
    // MARK: Authentication
    // change our internal state, this triggers an UI update on the main thread
    func updateUserData(withSignInStatus status : Bool) {
        DispatchQueue.main.async() {
            let userData : UserData = .shared
            userData.isSignedIn = status

            // when user is signed in, query the database, otherwise empty our model
            if (status && userData.notes.isEmpty) {
                self.queryNotes()
            } else {
                userData.notes = []
            }
        }
    }
    
    public func signIn() {

        // UIApplication.shared.windows.first is dprecated on iOS 15
        // solution from https://stackoverflow.com/questions/57134259/how-to-resolve-keywindow-was-deprecated-in-ios-13-0/57899013
        
        let w = UIApplication
                    .shared
                    .connectedScenes
                    .compactMap { $0 as? UIWindowScene }
                    .flatMap { $0.windows }
                    .first { $0.isKeyWindow }
        
        
        Amplify.Auth.signInWithWebUI(presentationAnchor: w!) { result in
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

        Amplify.Auth.signOut() { (result) in
            switch result {
            case .success:
                print("Successfully signed out")
            case .failure(let error):
                print("Sign out failed with error \(error)")
            }
        }
    }
    
    // MARK: API Access
    
    func queryNotes() {
        
        Amplify.API.query(request: .list(NoteData.self)) { event in
            switch event {
            case .success(let result):
                switch result {
                case .success(let notesData):
                    print("Successfully retrieved list of Notes")
                    
                    for n in notesData {
                        let note = Note.init(from: n)
                        DispatchQueue.main.async() {
                            UserData.shared.notes.append(note)
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
    
    func createNote(note: Note) {
        
        Amplify.API.mutate(request: .create(note.data)) { event in
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
    
    func deleteNote(note: Note) {
        
        Amplify.API.mutate(request: .delete(note.data)) { event in
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
    
    // MARK: Image Access
    
    func storeImage(name: String, image: Data) {
        
        let options = StorageUploadDataRequest.Options(accessLevel: .private)
        Amplify.Storage.uploadData(key: name, data: image, options: options,
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

        let options = StorageDownloadDataRequest.Options(accessLevel: .private)
        Amplify.Storage.downloadData(key: name, options: options,
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
        
        let options = StorageRemoveRequest.Options(accessLevel: .private)
        Amplify.Storage.remove(key: name, options: options,
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

}
    
