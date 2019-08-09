//
//  FieldAppUITests.swift
//  FieldAppUITests
//
//  Created by Kevin Bradbury on 9/19/17.
//  Copyright © 2017 Kevin Bradbury. All rights reserved.
//

import XCTest
import CoreLocation
import UIKit
import Alamofire
import Macaw
@testable import FieldApp

class FieldAppUITests: XCTestCase {
//    var app: XCUIApplication!
    
    override func setUp() {
        super.setUp()
        XCUIApplication().launch()
        // Put setup code here. This method is called before the invocation of each test method in the class.
        
        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false
        // UI tests must launch the application that they test. Doing this in setup will make sure it happens for each test method.
        
        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testExample() {
        // Use recording to get started writing UI tests.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }
    
    func testHomeVw() {
        let app = XCUIApplication()
        let showsHome = app.otherElements["Home View"].exists
        let showsBkgdView = app.otherElements["Home_bkgdView"].exists
        XCTAssertTrue(showsHome)
        XCTAssertTrue(showsBkgdView)
        
        let FanMenu = app.otherElements["Home_homeFanMenu"]
        FanMenu.tap() // Opens
        
        let MenuView = app.otherElements["Home_menuView"]
        let ProfileBtn = app.buttons["Home_profileBtn"]
        let UserLb = app.staticTexts["Home_userLabel"]
        let showsFanMenu = app.otherElements["Home_homeFanMenu"].exists
        let showsMenuView = app.otherElements["Home_menuView"].exists
        let showsProfileBtn = app.buttons["Home_profileBtn"].exists
        let showsUserLb = app.staticTexts["Home_userLabel"].exists
        XCTAssertTrue(showsFanMenu)
        XCTAssertTrue(showsMenuView)
        XCTAssertTrue(showsProfileBtn)
        XCTAssertTrue(showsUserLb)
        
        ProfileBtn.tap()
    }
    
    func testCOandAutoCompletePOfields() {
        let app = XCUIApplication()
        let FanMenu = app.otherElements["Home_homeFanMenu"]
        FanMenu.tap()
        // Manually segue to CO vc
        
        XCTAssertTrue(app.otherElements["ChangeOrders View"].exists)
        XCTAssertTrue(app.buttons["CO_backButton"].exists)
        XCTAssertTrue(app.staticTexts["CO_colorSpecLabel"].exists)
        XCTAssertTrue(app.textFields["CO_colorSpecText"].exists)
        XCTAssertTrue(app.datePickers["CO_datePickerFields"].exists)
        XCTAssertTrue(app.staticTexts["CO_descripLabel"].exists)
        XCTAssertTrue(app.textViews["CO_descripText"].exists)
        XCTAssertTrue(app.staticTexts["CO_formType"].exists)
        XCTAssertTrue(app.staticTexts["CO_jobNameLabel"].exists)
        XCTAssertTrue(app.staticTexts["CO_locationLabel"].exists)
        XCTAssertTrue(app.textFields["CO_locationText"].exists)
        XCTAssertTrue(app.staticTexts["CO_materialLabel"].exists)
        XCTAssertTrue(app.textFields["CO_materialText"].exists)
        XCTAssertTrue(app.staticTexts["CO_quantityLabel"].exists)
        XCTAssertTrue(app.textFields["CO_quantityText"].exists)
        XCTAssertTrue(app.staticTexts["CO_requestedByLabel"].exists)
        XCTAssertTrue(app.buttons["CO_sendButton"].exists)
        
        XCUIDevice.shared.orientation = .portrait
    }

    func testCOcompleteToCameraVw() {
        let app = XCUIApplication()
        let FanMenu = app.otherElements["Home_homeFanMenu"]
        FanMenu.tap()
        // Manually segue to CO vc
        
        let changeOrdersVw = app.otherElements["ChangeOrders View"]
        XCTAssertTrue(changeOrdersVw.exists)
        
        app/*@START_MENU_TOKEN@*/.buttons["CO_sendButton"]/*[[".otherElements[\"ChangeOrders View\"]",".buttons[\"SUBMIT\"]",".buttons[\"CO_sendButton\"]"],[[[-1,2],[-1,1],[-1,0,1]],[[-1,2],[-1,1]]],[0]]@END_MENU_TOKEN@*/.tap()
        XCUIDevice.shared.orientation = .portrait
        app.buttons["Cancel"].tap()
    }
    
    func testEmployeeIDentryVC() {
        let app = XCUIApplication()
        let FanMenu = app.otherElements["Home_homeFanMenu"]
        FanMenu.tap()
        // Manually segue to EmployeeID vc
        
        let employeeIDentryView = app.otherElements["EmployeeIDentry View"]
        XCTAssertTrue(app.otherElements["IDentry_animatedClockView"].exists)
        XCTAssertTrue(app.otherElements["IDentry_longHand"].exists)
        XCTAssertTrue(app.pickers["IDentry_roleSelection"].exists)
        XCTAssertTrue(employeeIDentryView.exists)
        
        XCUIApplication().otherElements["EmployeeIDentry View"].children(matching: .button).element(boundBy: 1).tap()
        
        XCTAssertTrue(app.otherElements["IDentry_manualPOentryVw"].exists)
        XCTAssertTrue(app.textFields["IDentry_poNumberField"].exists)
        XCTAssertTrue(app.buttons["IDentry_sendManualPOBtn"].exists)
        XCTAssertTrue(app.buttons["IDentry_cancelManualBtn"].exists)
        
        //        XCTAssertTrue(app.activityIndicators["IDentry_activityIndicator"].exists)
        //        XCTAssertTrue(app.otherElements["IDentry_activityBckgd"].exists)
        //        XCTAssertTrue(app.textFields["IDentry_enterIDText"].exists)
        //        XCTAssertTrue(app.textFields["IDentry_employeeID"].exists)
        //        XCTAssertTrue(app.buttons["IDentry_sendButton"].exists)
        //        XCTAssertTrue(app.buttons["IDentry_lunchBreakBtn"].exists)
        
    }
    
}

