//
//  UserData.swift
//  getting started
//
//  Created by Stormacq, Sebastien on 23/10/2020.
//  Copyright © 2020 Stormacq, Sebastien. All rights reserved.
//

/*
 Please check
 NoteData+Schema.swift :26
 model.listPluralName = "NoteData"

 https://github.com/aws-amplify/amplify-ios/issues/1443
 https://github.com/aws-amplify/amplify-codegen/pull/255
 https://github.com/aws-amplify/amplify-ios/pull/1451
 */

import Foundation
import SwiftUI

enum AppState {
    case signedOut
    case loading
    case dataAvailable([Note])
    case error(Error)
}

// singleton object to store user data
@MainActor
class ViewModel : ObservableObject {
    
    @Published var state : AppState = .signedOut
    
    // MARK: Manage the notes
    
    // just a local cache
    var notes : [Note] = []

    // load notes from the backend
    @discardableResult
    func loadNotes() async -> [Note] {
        if self.notes.isEmpty {
            self.notes = await Backend.shared.queryNotes()
        }
        self.state = .dataAvailable(self.notes)
        return self.notes
    }

    // add a note to the mode and the backend 
    func addNote(name: String, description: String?, image: UIImage?) async {

        let note = Note(id : UUID().uuidString,
                        name: name,
                        description: description,
                        createdAt: Date.now)

        // asynchronously store the note (and assume it will succeed)
        Task {
            await Backend.shared.createNote(note: note)
        }
        
        if let i = image  {
            let smallImage = i.resize(to: 0.10)
            note.imageName = UUID().uuidString

            Task {
                // asynchronously store the image (and assume it will work)
                print("Initiating the image upload")
                await Backend.shared.storeImage(name: note.imageName!, image: (smallImage.pngData())!)
                
                // asynchronously generate the URL of the image.
                note.imageURL = await Backend.shared.imageURL(name: note.imageName!)
            }
        }
        
        self.notes.append(note)
        
        // force UI update
        self.state = .dataAvailable(self.notes)
    }
    
    // delete a node from the model and the backend
    func deleteNote(at: Int) {

        let note = self.notes.remove(at: at)
        
        // asynchronously remove from database
        Task {
            await Backend.shared.deleteNote(note: note)
            
            if let n = note.imageName {
                await Backend.shared.deleteImage(name: n)
            }
        }
    }
    
    // MARK: Authentication
    
    public func getInitialAuthStatus() async throws {
        
        // when running swift UI preview - do not change isSignedIn flag
        if !EnvironmentVariable.isPreview {
            
            let status = try await Backend.shared.getInitialAuthStatus()
            print("INITIAL AUTH STATUS is \(status)")
            switch status {
            case .signedIn: self.state = .loading
            case .signedOut, .sessionExpired:  self.state = .signedOut
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
                    self.state = .signedOut
                }
            }
            print("==== EXITED AUTH STATUS LOOP =====")
    }
    
    // asynchronously sign in
    // change of sttaus will be picked up by `listenAuthUpdate`
    // that will trigger the UI update
    public func signIn() {
        Task {
            await Backend.shared.signIn()
        }
    }
    
    // asynchronously sign out
    // change of sttaus will be picked up by `listenAuthUpdate`
    // that will trigger the UI update
    public func signOut() {
        Task {
            await Backend.shared.signOut()
        }
    }
}

extension ViewModel {
    static var mock : ViewModel = mockedData(isSignedIn: true)
    static var signedOutMock : ViewModel = mockedData(isSignedIn: false)

    private static func mockedData(isSignedIn: Bool) -> ViewModel {
        let model = ViewModel()
        let desc = "this is a very long description that should fit on multiiple lines.\nit even has a line break\nor two."
        
        let n1 = Note(id: "01", name: "Hello world", description: desc, image: "mic")
        let n2 = Note(id: "02", name: "A new note", description: desc, image: "phone")
        model.notes = [ n1, n2 ]
        if isSignedIn {
            model.state = .dataAvailable(model.notes)
        } else {
            model.state = .signedOut
        }

        n1.imageURL = Bundle.main.url(forResource: "4BC64B0D-A56E-4218-9993-C5C4EDF9C044", withExtension: "png")
        n2.imageURL = Bundle.main.url(forResource: "27F5F399-2D1D-476F-84BB-E50913535352", withExtension: "png")

        return model
    }
}

