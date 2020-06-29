//
//  ContentView.swift
//  getting started
//
//  Created by Stormacq, Sebastien on 26/06/2020.
//  Copyright © 2020 Stormacq, Sebastien. All rights reserved.
//

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
    @Published var image : Image?
        
    init(id: String, name: String) {
        self.id = id
        self.name = name
    }

    convenience init(id: String, name: String, description: String, image: String) {
        self.init(id: id, name: name)
        self.description = description
        self.imageName = image
    }

    init(from: NoteData) {
        self.id          = from.id
        self.name        = from.name
        self.description = from.description
        self.imageName   = from.image
        
        if let name = self.imageName {
            // asynchronously download the image
            Backend.shared.retrieveImage(name: name) { (data) in
                DispatchQueue.main.async() {
                    let uim = UIImage(data: data)
                    self.image = Image(uiImage: uim!)
                }
            }
        }
        // store API object for easy retrieval later
        self._data = from
    }
    
    fileprivate var _data : NoteData?
    
    // access the privately stored NoteData or build one if we don't have one.
    var data : NoteData {

        if (_data == nil) {

            _data = NoteData(id: self.id,
                             name: self.name,
                             description: self.description,
                             image: self.imageName)
        }
        
        return _data!
    }
    
}

struct ListRow: View {
    @ObservedObject var note : Note
    var body: some View {
        
        return HStack(alignment: .center, spacing: 5.0) {
            
            if (note.image != nil) {
                note.image!
                .resizable()
                .frame(width: 50, height: 50)
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
    @State var showCreateNote = false
    
    @State var name : String        = "New Note"
    @State var description : String = "This is a new note"
    @State var image : String       = "image"

    var body: some View {

        ZStack {
            if (userData.isSignedIn) {
                NavigationView {
                    List {
                        ForEach(userData.notes) { note in
                            ListRow(note: note)
                        }.onDelete() { (indexSet) in
                            // we might receive multiple indexes when view is in edit mode
                            let indexes = Array(indexSet)
                            for i in indexes {
                                // removing from user data will refresh UI
                                let note = self.userData.notes.remove(at: i)
                                // asynchronously remove from database
                                Backend.shared.deleteNote(note: note)
                                
                                if let n = note.imageName {
                                    // asynchronously delete the image
                                    Backend.shared.deleteImage(name: n)
                                }
                            }
                        }
                    }
                    .navigationBarTitle(Text("Notes"))
                    .navigationBarItems(leading: SignOutButton(), trailing: Button(action: {
                        self.showCreateNote.toggle()
                    }) {
                        Image(systemName: "plus")
                    })
                }.sheet(isPresented: $showCreateNote) {
                    AddNoteView(isPresented: self.$showCreateNote, userData: self.userData)
                }
            } else {
                SignInButton()
            }
        }
    }
}

struct AddNoteView: View {
    @Binding var isPresented: Bool
    var userData: UserData

    @State var name : String        = "New Note"
    @State var description : String = "This is a new note"
    @State var image : UIImage?
    @State var showCaptureImageView = false

    var body: some View {
        Form {
        
            Section(header: Text("TEXTE")) {
                TextField("Name", text: $name)
                TextField("Name", text: $description)
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
                    if (image != nil ) {
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
            }

            Section {
                Button(action: {
                    self.isPresented = false
                    
                    let imageName = UUID().uuidString
                    
                    let note = Note(id : UUID().uuidString,
                                    name: self.$name.wrappedValue,
                                    description: self.$description.wrappedValue,
                                    image: imageName)

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
        }
    }
}
    
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


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {

        let _ = prepareTestData()
        
        return ContentView()
//        return AddNoteView(isPresented: .constant(true), userData: UserData.shared)
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
    n1.image = Image(systemName: n1.imageName!)
    n2.image = Image(systemName: n2.imageName!)
    return userData
}
