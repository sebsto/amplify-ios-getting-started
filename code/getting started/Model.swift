//
//  Model.swift
//  getting started
//
//  Created by Stormacq, Sebastien on 22/02/2023.
//  Copyright © 2023 Stormacq, Sebastien. All rights reserved.
//

import Foundation

class Note : Identifiable, ObservableObject {
    var id          : String
    var name        : String
    var description : String?
    var imageName   : String?
    var createdAt   : Date?
    @MainActor @Published var imageURL : URL?
    
    init(id: String,
         name: String,
         description: String? = nil,
         image: String? = nil,
         createdAt: Date? = nil) {
        self.id          = id
        self.name        = name
        self.description = description
        self.imageName   = image
        self.createdAt   = createdAt
    }
    
    // convert from backend data struct to our model
    convenience init(from data: NoteData) {
        self.init(id: data.id,
                  name: data.name,
                  description: data.description,
                  image: data.image,
                  createdAt: data.createdAt?.foundationDate)
        
        if let name = self.imageName {
            
            // asynchronously generate the URL of the image.
            Task { @MainActor () -> Void in
                self.imageURL = await Backend.shared.imageURL(name: name)
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
    
    // provide a display ready representatin of the date
    var date: String {
        get {
            if let date = self.createdAt {
                let formatter = DateFormatter()
                formatter.dateStyle = .short
                return formatter.string(from: date)
            } else {
                return ""
            }
        }
    }
}
