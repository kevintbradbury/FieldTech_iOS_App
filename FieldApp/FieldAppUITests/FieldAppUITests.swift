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
    var app: XCUIApplication!
    
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
        
//        let window = app.children(matching: .window).element(boundBy: 0)
//        let element = window.children(matching: .other).element.children(matching: .other).element.children(matching: .other).element(boundBy: 0).children(matching: .other).element
//        element.tap()
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
    
    func testCOview() {
        let app = XCUIApplication()
        let FanMenu = app.otherElements["Home_homeFanMenu"]
        FanMenu.tap()
        // Manually segue to CO vc
        
        let showsCOviews = [
            app.otherElements["ChangeOrders View"].exists,
            app.otherElements["CO_backButton"].exists,
            app.otherElements["CO_colorSpecLabel"].exists,
            app.otherElements["CO_colorSpecText"].exists,
            app.otherElements["CO_datePickerFields"].exists,
            app.otherElements["CO_descripLabel"].exists,
            app.otherElements["CO_descripText"].exists,
            app.otherElements["CO_formType"].exists,
            app.otherElements["CO_jobNameLabel"].exists,
            app.otherElements["CO_locationLabel"].exists,
            app.otherElements["CO_locationText"].exists,
            app.otherElements["CO_materialLabel"].exists,
            app.otherElements["CO_materialText"].exists,
            app.otherElements["CO_quantityLabel"].exists,
            app.otherElements["CO_quantityText"].exists,
            app.otherElements["CO_requestedByLabel"].exists,
            app.otherElements["CO_sendButton"].exists
        ]
        
        for truefalse in showsCOviews {
            XCTAssertTrue(truefalse)
        }
    }
    
}

