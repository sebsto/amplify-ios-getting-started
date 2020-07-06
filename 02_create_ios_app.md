# Create an iOS App

add step by step project creation guide with Xcode screenshots

## Update the main view

Open `ContentView.swift` and replace the code with this content:

```swift
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

    init(id: String, name: String) {
        self.id = id
        self.name = name
    }
}

struct ListRow: View {
    @ObservedObject var note : Note
    var body: some View {

        return HStack(alignment: .center, spacing: 5.0) {

            if ((note.imageName) != nil) {
                Image(systemName: note.imageName!)
                .resizable()
                .frame(width: 50, height: 50)
                .padding()
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

    var body: some View {
        List {
            ForEach(userData.notes) { note in
                ListRow(note: note)
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {

        let _ = prepareTestData()

        return ContentView()
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
    return userData
}

```