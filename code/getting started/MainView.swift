//
//  ContentView.swift
//  getting started
//
//  Created by Stormacq, Sebastien on 26/06/2020.
//  Copyright © 2020 Stormacq, Sebastien. All rights reserved.
//

import SwiftUI

struct MainView: View {
    @EnvironmentObject public var model: MainViewModel
    @State var showCreateNote = false
    
    var body: some View {

        ZStack {
            switch(model.state) {
            case .signedOut:
                VStack {
                    SignInButton()
                    SignOutButton()
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
            .navigationTitle(Text("Your Memories"))

            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    SignOutButton()
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
            
            Text("2023-06-23")
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
//            .background(.gray)
        }
        .padding([.top, .bottom], 20)
    }
}

struct AddNoteView: View {
    @Binding var isPresented: Bool
    var model: MainViewModel

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
    var body: some View {
        Button(action: { Task { await Backend.shared.signIn() }}){
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
        Button(action: { Task { await Backend.shared.signOut() }}) {
                Text("Sign Out")
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {

        let user1 = MainViewModel.mock
        let user2 = MainViewModel.signedOutMock
        return Group {
            MainView().environmentObject(user1)
            MainView().environmentObject(user2)
            AddNoteView(isPresented: .constant(true), model: user1)
        }
    }
}

