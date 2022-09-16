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

// singleton object to store user data
class UserData : ObservableObject {
    private init() {}
    static let shared = UserData()
    
    @Published var notes      : [Note] = []
    @Published var isSignedIn : Bool   = false
}

class Note : Identifiable, ObservableObject {
    var id          : String
    var name        : String
    var description : String?
    var imageName   : String?
    @Published var image : Image?
        
    init(id: String, name: String, description: String? = nil, image: String? = nil ) {
        self.id          = id
        self.name        = name
        self.description = description
        self.imageName   = image
    }

    // the callback is just used for testability
    //convenience init(from data: NoteData, _ completion: ((Image?) -> Void)? = nil ) {
    convenience init(from data: NoteData) {
        self.init(id: data.id, name: data.name, description: data.description, image: data.image)
        
        if let name = self.imageName {
            
            // asynchronously download the image.
            Task {
                let data = await Backend.shared.retrieveImage(name: name)
                
                // run in a separate function
                // updates the UI on the main thread
                await self.updateImageData(data)
            }
            
        }
        // store API object for easy retrieval later
        self._data = data
    }

    // asynchronously update the UI
    @MainActor
    private func updateImageData(_ data: Data) async {
        
        // convert Data -> UIImage -> Image
        let uim = UIImage(data: data)
        self.image = Image(uiImage: uim!) // this line will trigger an UI update

    }
    
    // MARK: mapping between Note and NoteData
    
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
