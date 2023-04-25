//
//  ContentView.swift
//  getting started
//
//  Created by Stormacq, Sebastien on 26/06/2020.
//  Copyright © 2020 Stormacq, Sebastien. All rights reserved.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject public var model: ViewModel
    @State var showCreateNote = false
    
    var body: some View {

        ZStack {
            switch(model.state) {
            case .signedOut:
                VStack {
                    SignInButton(model : self.model)
                        .padding(.bottom)
                    SignOutButton(model : self.model)
                }
                
            case .loading:
                ProgressView()
                    .task() {
                        await self.model.loadNotes()
                    }
                
            case .dataAvailable(let notes):
                navigationView(notes: notes)
                
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
    func navigationView(notes: [Note]) -> some View {
        NavigationView {
            List {
                ForEach(notes) { note in
                    ListRow(note: note)
                }.onDelete { indices in
                    indices.forEach {
                        self.model.deleteNote(at: $0)
                    }
                }
            }
            .navigationTitle(Text("My Memories"))

            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    SignOutButton(model: self.model)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        self.showCreateNote.toggle()
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
        }
        .sheet(isPresented: $showCreateNote) {
            AddNoteView(isPresented: self.$showCreateNote, model: self.model)
        }
    }
}

struct ListRow: View {
    @ObservedObject var note : Note
    var body: some View {
        
        VStack(alignment: .leading) {
            
            Text(note.date)
                .bold()
            
            AsyncImage(url: note.imageURL) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .padding(.bottom)
            } placeholder: {
                ProgressView()
                    .frame(maxWidth: .infinity)
            }

            Group {
                Text(note.name)
                    .bold()
                
                if let description = note.description {
                    Text(description)
                        .foregroundColor(.gray)
                }
            }
            .background(.gray)
        }
        .padding([.top, .bottom], 20)
    }
}

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
                            Spacer()
                            }
                    }
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
    
struct SignInButton: View {
    var model : ViewModel
    var body: some View {
        Button(action: { self.model.signIn() }){
            HStack {
                Image(systemName: "person.fill")
                    .scaleEffect(2)
                    .padding()
                Text("Sign In")
                    .font(.largeTitle)
                    .bold()
            }
            .padding()
            .foregroundColor(.white)
            .background(Color.green)
            .cornerRadius(30)
        }
    }
}

struct SignOutButton : View {
    var model : ViewModel
    var body: some View {
        Button(action: { self.model.signOut() }) {
                Text("Sign Out")
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {

        let user1 = ViewModel.mock
        let user2 = ViewModel.signedOutMock
        return Group {
            ContentView().environmentObject(user1)
            ContentView().environmentObject(user2)
            AddNoteView(isPresented: .constant(true), model: user1)
        }
    }
}

