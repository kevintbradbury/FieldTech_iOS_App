//
//  FieldAppTests.swift
//  FieldAppTests
//
//  Created by Kevin Bradbury on 9/19/17.
//  Copyright © 2017 Kevin Bradbury. All rights reserved.
//

import XCTest
import FirebaseCore
import CoreLocation
@testable import FieldApp

class FieldAppTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        //        self.measure { /* Put the code you want to measure the time of here.  */ }
    }
}

class APICallsTests: XCTestCase {
    
    func testIfHostSet() {
        let testHost = "https://www.mb-test-server-01.de/"
        APICalls.getHostFromPList()
        
        XCTAssertEqual(testHost, APICalls.host, "Test Host name equal")
        XCTAssertNotNil(APICalls.host)
    }
    
    func testCheckFIRtoken() {
        let promiseNoTk = expectation(description: "No token or invalid employee")
        let promiseHasTk = expectation(description: "Has token")
        
        APICalls().checkForToken(employeeID: "9999") { hasTkn in
            XCTAssertFalse(hasTkn)
            promiseNoTk.fulfill()
        }
        APICalls().checkForToken(employeeID: "200") { hasTkn in
            XCTAssertTrue(hasTkn)
            promiseHasTk.fulfill()
        }
        wait(for: [promiseNoTk, promiseHasTk], timeout: 10)
    }
    
    func testGetJbInfo() {
        let promiseWithInfo = expectation(description: "Gets user jobs, tOff, & holidays back")
        let promiseNoInfo = expectation(description: "No info back")
        
        APICalls().fetchJobInfo(employeeID: "200") { (userJobs, tmOff, holidays) in
            XCTAssertNotNil(userJobs)
            XCTAssertNotNil(tmOff)
            XCTAssertNotNil(holidays)
            promiseWithInfo.fulfill()
        }
        
        APICalls().fetchJobInfo(employeeID: "9999") { (userJob, tmOff, holidays) in
            promiseNoInfo.fulfill()
        }
        
        wait(for: [promiseWithInfo, promiseNoInfo], timeout: 10)
    }
    
    func testSendCoords() {
        let correctCoords = CLLocationCoordinate2D(latitude: 33.9093983, longitude: -118.1247946)
        let correctCoords2 = CLLocationCoordinate2D(latitude: 33.877223, longitude: -118.035077)
        let incrtCoords = CLLocationCoordinate2D(latitude: -33.877135, longitude: -18.035323)
        let crtDates = Job.UserJob.JobDates(
            installDate: Date(timeIntervalSince1970: Date().timeIntervalSince1970), endDate: Date().addingTimeInterval(TimeInterval(Date().timeIntervalSince1970 * 60 * 60 * 4))
        )
        let crtJb = Job.UserJob(poNumber: "2020", jobName: "Foster and Bellflower", dates: [crtDates], jobLocation: correctCoords,
            jobAddress: "13400 Bellflower Blvd", jobCity: "Bellflower", jobState: "CA", projCoord: "Pete", fieldLead: "", supervisor: "", assignedEmployees: ["Loyd_Christmas"])
        let crtJb2 = Job.UserJob(poNumber: "0", jobName: "Millwork HQ", dates: [crtDates], jobLocation: correctCoords2,
            jobAddress: "13921 Bettencourt", jobCity: "Cerritos", jobState: "CA", projCoord: "Pete", fieldLead: "", supervisor: "", assignedEmployees: ["Loyd_Christmas"]
        )
        let incrtJb = Job.UserJob(poNumber: "132-A", jobName: "Hawthorne Gardens", dates: [crtDates], jobLocation: correctCoords,
            jobAddress: "900 Artesia", jobCity: "Redondo Beach", jobState: "CA", projCoord: "", fieldLead: "", supervisor: "", assignedEmployees: [""])
        let correctUserInfo = UserData.UserInfo(employeeID: 200, userName: "Loyd_Christmas", employeeJobs: [crtJb], punchedIn: true)
        let correctUserInfo2 = UserData.UserInfo(employeeID: 505, userName: "Charles_Xavier", employeeJobs: [crtJb2], punchedIn: true)
        let incorrectUserInfo = UserData.UserInfo(employeeID: 9999, userName: "Buddy_ Holly", employeeJobs: [incrtJb], punchedIn: false)
        let incorrectUserInfo2 = UserData.UserInfo(employeeID: -1, userName: "", employeeJobs: [incrtJb], punchedIn: true)
        
        let promiseWithSuccess = expectation(description: "Sends proper info and receives proper info")
        let promiseFail = expectation(description: "Error due to incorrect info")
        promiseWithSuccess.expectedFulfillmentCount = 2
        promiseFail.expectedFulfillmentCount = 2
        
        APICalls().sendCoordinates(
            employee: correctUserInfo, location: correctCoords, autoClockOut: false, role: "Field", po: crtJb.poNumber, override: false
        ) { (success, currentJob, poNum, jobCoords, clockedIn, err) in
            XCTAssertTrue(success)
            XCTAssertNotNil(currentJob); XCTAssertNotNil(poNum); XCTAssertNotNil(jobCoords); XCTAssertNotNil(clockedIn)
            promiseWithSuccess.fulfill()
        }
        
        APICalls().sendCoordinates(employee: incorrectUserInfo, location: incrtCoords, autoClockOut: false, role: "", po: "", override: false) { (success, currentJob, poNum, jobCoords, clockedIn, err) in
            XCTAssertFalse(success); XCTAssertNotNil(err)
            promiseFail.fulfill()
        }
        
        APICalls().sendCoordinates(employee: incorrectUserInfo2, location: incrtCoords, autoClockOut: true, role: "", po: "", override: true) { (success, currentJob, poNum, jobCoords, clockedIn, err) in
            XCTAssertFalse(success)
            XCTAssertNotNil(err)
            XCTAssertTrue(clockedIn)
            promiseFail.fulfill()
        }
        
        APICalls().sendCoordinates(
            employee: correctUserInfo2, location: correctCoords2, autoClockOut: true, role: "Field", po: crtJb.poNumber, override: false
        ) { (success, currentJob, poNum, jobCoords, clockedIn, err) in
            XCTAssertTrue(success)
            XCTAssertNotNil(currentJob); XCTAssertNotNil(poNum); XCTAssertNotNil(jobCoords); XCTAssertNotNil(clockedIn)
            promiseWithSuccess.fulfill()
        }
        
        wait(for: [promiseWithSuccess, promiseFail], timeout: 20)
    }
    
    func testJustSendCoords() {
        let promise = expectation(description: "Checked coords")
        promise.expectedFulfillmentCount = 2
        UserDefaults.standard.set("0", forKey: DefaultKeys.todaysJobPO)
        
        guard let coordinates = UserLocation.instance.currentCoordinate else {
            XCTFail(); return
        }
        
        APICalls().justCheckCoordinates(location: coordinates) { success in
            XCTAssertTrue(success)
            promise.fulfill()
        }
        let coordinates2 = CLLocationCoordinate2D(latitude: 0.0, longitude: 0.0)
        APICalls().justCheckCoordinates(location: coordinates2) { success in
            XCTAssertFalse(success)
            promise.fulfill()
        }
        
        wait(for: [promise], timeout: 10)
    }
    
    func testSendJbCheckup() {
        let blankData = Data()
        var actualData = Data()
        let mockCheckUp = Job.JobCheckupInfo(returnTomorrow: true, numberOfWorkers: 5, addedMaterial: true, poNumber: "2020")
        let promise = expectation(description: "Finished sending jbCheckup")
        promise.expectedFulfillmentCount = 2
        
        APICalls().sendJobCheckup(po: "", body: blankData) {
            promise.fulfill()
        }
        
        do {
            let jsonEncoder = JSONEncoder()
            actualData = try jsonEncoder.encode(mockCheckUp)
        } catch {
            print(error); XCTFail()
        }
        
        APICalls().sendJobCheckup(po: "2020", body: actualData) {
            promise.fulfill()
        }
        
        wait(for: [promise], timeout: 15)
    }
    
    func testFetchEmply() {
        let promise = expectation(description: "Finished getting employee info")
        
        APICalls().fetchEmployee(employeeId: 200) { (usrInfo, userAdrs) in
            XCTAssertNotNil(usrInfo)
            XCTAssertNotNil(userAdrs)
            promise.fulfill()
        }
        
        wait(for: [promise], timeout: 10)
    }
}
