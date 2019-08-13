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
        // Wait for return from Server
        
        XCTAssertTrue(app.otherElements["IDentry_manualPOentryVw"].exists)
        XCTAssertTrue(app.textFields["IDentry_poNumberField"].exists)
        XCTAssertTrue(app.buttons["IDentry_sendManualPOBtn"].exists)
        XCTAssertTrue(app.buttons["IDentry_cancelManualBtn"].exists)
        
        // Manually tap textfield here & 'more' key
        XCUIDevice.shared.orientation = .portrait
        
        let key = app/*@START_MENU_TOKEN@*/.keys["0"]/*[[".keyboards.keys[\"0\"]",".keys[\"0\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/
        key.tap()
        key.tap()
        
        let deleteKey = app/*@START_MENU_TOKEN@*/.keys["delete"]/*[[".keyboards.keys[\"delete\"]",".keys[\"delete\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/
        deleteKey.tap()
        
        app/*@START_MENU_TOKEN@*/.otherElements["IDentry_manualPOentryVw"]/*[[".otherElements[\"EmployeeIDentry View\"].otherElements[\"IDentry_manualPOentryVw\"]",".otherElements[\"IDentry_manualPOentryVw\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
        app/*@START_MENU_TOKEN@*/.buttons["IDentry_sendManualPOBtn"]/*[[".otherElements[\"EmployeeIDentry View\"]",".otherElements[\"IDentry_manualPOentryVw\"]",".buttons[\"Send\"]",".buttons[\"IDentry_sendManualPOBtn\"]"],[[[-1,3],[-1,2],[-1,1,2],[-1,0,1]],[[-1,3],[-1,2],[-1,1,2]],[[-1,3],[-1,2]]],[0]]@END_MENU_TOKEN@*/.tap()
        XCUIDevice.shared.orientation = .faceUp
        //        XCTAssertTrue(app.buttons["IDentry_lunchBreakBtn"].exists)
    }
    
    func testSchedule() {
        
        let app = XCUIApplication()
        let homeMenuviewElement = app/*@START_MENU_TOKEN@*/.otherElements["Home_menuView"]/*[[".otherElements[\"Home View\"]",".otherElements[\"Home_homeFanMenu\"].otherElements[\"Home_menuView\"]",".otherElements[\"Home_menuView\"]"],[[[-1,2],[-1,1],[-1,0,1]],[[-1,2],[-1,1]]],[0]]@END_MENU_TOKEN@*/
        homeMenuviewElement.tap()
        homeMenuviewElement.tap()
        // Manual segue to Calendar
        
        let cellsQuery = app.collectionViews.cells
        cellsQuery.otherElements.containing(.staticText, identifier:"13").element.tap()
        cellsQuery.otherElements.containing(.staticText, identifier:"7").element.tap()
        
        XCTAssertTrue(app.otherElements["Schedule View"].exists)
        XCTAssertTrue(app.collectionViews["Sched_calendarView"].exists)
        XCTAssertTrue(app.tables["Sched_jobsTable"].exists)
        XCTAssertTrue(app.staticTexts["Sched_monthLabel"].exists)
        XCTAssertTrue(app.staticTexts["Sched_yearLabel"].exists)
        XCTAssertTrue(app.buttons["Sched_backButton"].exists)
        XCTAssertTrue(app.otherElements["Sched_jobDetailView"].exists)
        XCTAssertTrue(app.staticTexts["Sched_jobNameLbl"].exists)
        XCTAssertTrue(app.staticTexts["Sched_poNumberLbl"].exists)
        XCTAssertTrue(app.staticTexts["Sched_installDateLbl"].exists)
        
        XCUIApplication().buttons["Accept More Hours"].tap()
        
        XCTAssertTrue(app.otherElements["Sched_daysOfWeekView"].exists)
        XCTAssertTrue(app.switches["Sched_sundaySwitch"].exists)
        XCTAssertTrue(app.switches["Sched_mondaySwitch"].exists)
        XCTAssertTrue(app.switches["Sched_tuesdaySwitch"].exists)
        XCTAssertTrue(app.switches["Sched_wednesdaySwitch"].exists)
        XCTAssertTrue(app.switches["Sched_thursdaySwitch"].exists)
        XCTAssertTrue(app.switches["Sched_fridaySwitch"].exists)
        XCTAssertTrue(app.switches["Sched_saturdaySwitch"].exists)
        XCTAssertTrue(app.buttons["Sched_submitBtn"].exists)
        XCTAssertTrue(app.buttons["Sched_cancelBtn"].exists)
        
        XCUIApplication().buttons["X"].tap()
    }
    
    func testToolRental() {
        
        let app = XCUIApplication()
        let homeMenuviewElement = app/*@START_MENU_TOKEN@*/.otherElements["Home_menuView"]/*[[".otherElements[\"Home View\"]",".otherElements[\"Home_homeFanMenu\"].otherElements[\"Home_menuView\"]",".otherElements[\"Home_menuView\"]"],[[[-1,2],[-1,1],[-1,0,1]],[[-1,2],[-1,1]]],[0]]@END_MENU_TOKEN@*/
        homeMenuviewElement.tap()
        // Manually select ToolRentals
        
        app.alerts["Rent or Return"].buttons["Rental"].tap()
        
        let changeordersViewElement = app.otherElements["ChangeOrders View"]
        changeordersViewElement.tap()
    }
    
    func testToolReturn() {
        
        let app = XCUIApplication()
        let homeMenuviewElement = app/*@START_MENU_TOKEN@*/.otherElements["Home_menuView"]/*[[".otherElements[\"Home View\"]",".otherElements[\"Home_homeFanMenu\"].otherElements[\"Home_menuView\"]",".otherElements[\"Home_menuView\"]"],[[[-1,2],[-1,1],[-1,0,1]],[[-1,2],[-1,1]]],[0]]@END_MENU_TOKEN@*/
        homeMenuviewElement.tap()
        // Manually select Tool Return
        
        app.alerts["Rent or Return"].buttons["Return"].tap()
        
        XCTAssertTrue(app.tables["ToolRtn_table"].exists)
        XCTAssertTrue(app.buttons["ToolRtn_backButton"].exists)
        //        XCTAssertTrue(app.otherElements["ToolReturn View"].exists)
        //        XCTAssertTrue(app.navigationBars["ToolRtn_navBar"].exists)
        
        // Manually select table cell
        app.alerts["Confirm Tool Return"].buttons["YES"].tap()
        
        XCTAssertTrue(app.otherElements["ToolSignOff View"].exists)
        XCTAssertTrue(app.staticTexts["ToolSgn_dateLabel"].exists)
        XCTAssertTrue(app.buttons["ToolSgn_backBtn"].exists)
        XCTAssertTrue(app.buttons["ToolSgn_returnerBtn"].exists)
        XCTAssertTrue(app.textFields["ToolSgn_printNameRenterField"].exists)
        XCTAssertTrue(app.buttons["ToolSgn_receiverBtn"].exists)
        XCTAssertTrue(app.textFields["ToolSgn_printNameReceiverField"].exists)
        XCTAssertTrue(app.buttons["ToolSgn_sendButton"].exists)
        XCTAssertTrue(app.otherElements["ToolSgn_returnerSIgnatureView"].exists)
        XCTAssertTrue(app.otherElements["ToolSgn_receiverSignatureView"].exists)
//        XCTAssertTrue(app.otherElements["ToolSgn_activityIndicator"].exists)
//        XCTAssertTrue(app.otherElements["ToolSgn_activityBckgd"].exists)
        
        let window = app.children(matching: .window).element(boundBy: 0)
        let element = window.children(matching: .other).element(boundBy: 2).children(matching: .other).element
        element.children(matching: .button).matching(identifier: "SIGN").element(boundBy: 0).tap()
        
        let element2 = window.children(matching: .other).element(boundBy: 3).children(matching: .other).element.children(matching: .other).element.children(matching: .other).element.children(matching: .other).element.children(matching: .other).element(boundBy: 0)
        element2/*@START_MENU_TOKEN@*/.swipeLeft()/*[[".swipeDown()",".swipeLeft()"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/
        
        let doneButton = app.navigationBars["Initial here"].buttons["Done"]
        doneButton.tap()
        element.children(matching: .button).matching(identifier: "SIGN").element(boundBy: 1).tap()
        element2/*@START_MENU_TOKEN@*/.swipeLeft()/*[[".swipeDown()",".swipeLeft()"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/
        doneButton.tap()
    }
    
    func testSuppliesReq() {
        
        let app = XCUIApplication()
        let homeMenuviewElement = app/*@START_MENU_TOKEN@*/.otherElements["Home_menuView"]/*[[".otherElements[\"Home View\"]",".otherElements[\"Home_homeFanMenu\"].otherElements[\"Home_menuView\"]",".otherElements[\"Home_menuView\"]"],[[[-1,2],[-1,1],[-1,0,1]],[[-1,2],[-1,1]]],[0]]@END_MENU_TOKEN@*/
        homeMenuviewElement.tap()
        // Manual select SupplieReq Map
        
        app.alerts["Field Supplies"].buttons["Pick up from Store"].tap()
        app.children(matching: .window).element(boundBy: 0).children(matching: .other).element(boundBy: 1).children(matching: .other).element.children(matching: .other).element.children(matching: .other).element.children(matching: .other).element.children(matching: .other).matching(identifier: "Lowe's, ‭+1 (562) 926-0826‬").element(boundBy: 0).tap()
        
        let loweS15629260826Element = app.otherElements["Lowe's, ‭+1 (562) 926-0826‬"]
    }
    
}

