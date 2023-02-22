//
//  App.swift
//  getting started
//
//  Created by Stormacq, Sebastien on 16/09/2022.
//  Copyright © 2022 Stormacq, Sebastien. All rights reserved.
//

import SwiftUI


@main
struct GettingStartedApp: App {

    // trigger initialization of the Backend
    let backend = Backend.shared

    var body: some Scene {

        WindowGroup {
            ContentView().environmentObject(ViewModel())
        }
    }
}
