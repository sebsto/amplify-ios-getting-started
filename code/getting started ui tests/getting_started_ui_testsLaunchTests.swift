//
//  getting_started_ui_testsLaunchTests.swift
//  getting started ui tests
//
//  Created by Stormacq, Sebastien on 30/09/2021.
//  Copyright © 2021 Stormacq, Sebastien. All rights reserved.
//

import XCTest

class getting_started_ui_testsLaunchTests: XCTestCase {

    override class var runsForEachTargetApplicationUIConfiguration: Bool {
        true
    }

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testLaunch() throws {
        let app = XCUIApplication()
        app.launch()

        // Insert steps here to perform after app launch but before taking a screenshot,
        // such as logging into a test account or navigating somewhere in the app

        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Launch Screen"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
