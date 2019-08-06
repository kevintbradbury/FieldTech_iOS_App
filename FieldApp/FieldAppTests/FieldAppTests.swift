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
        promise.expectedFulfillmentCount = 2
        
        APICalls().fetchEmployee(employeeId: 200) { (usrInfo, userAdrs) in
            XCTAssertNotNil(usrInfo)
            XCTAssertNotNil(userAdrs)
            promise.fulfill()
        }
        APICalls().fetchEmployee(employeeId: 9999) { (usrInfo, userAdrs) in
            promise.fulfill()
        }
        wait(for: [promise], timeout: 10)
    }
    
    func testGetSafetyQs() {
        let promise = expectation(description: "Gets 2 Safety Qs from Server.")
        
        APICalls().getSafetyQs() { safetyQs in
            XCTAssertNotNil(safetyQs)
            XCTAssertEqual(safetyQs.count, 2)
            promise.fulfill()
        }
        wait(for: [promise], timeout: 10)
    }
    
    func testAcceptMoreDays() {
        let daysToAccept = AcceptMoreDays(sun: true, mon: true, tue: true, wed: true, thu: true, fri: true, sat: true)
        let promise = expectation(description: "Returns successfully if employee exists.")
        promise.expectedFulfillmentCount  = 2
        
        APICalls().acceptMoreHrs(employee: "Loyd_Christmas", moreDays: daysToAccept) { success in
            XCTAssertTrue(success)
            promise.fulfill()
        }
        APICalls().acceptMoreHrs(employee: "", moreDays: daysToAccept) { success in
            XCTAssertFalse(success)
            promise.fulfill()
        }
        wait(for: [promise], timeout: 10)
    }

    func testGetToolsNimages() {
        let promise = expectation(description: "Returns successfully if has Tools and Images.")
        promise.expectedFulfillmentCount = 2
        
        APICalls().getToolRentals(employeeID: 200) { toolsNimgs in
            XCTAssertNotNil(toolsNimgs)
            XCTAssertNotNil(toolsNimgs!.images)
            XCTAssertNotNil(toolsNimgs!.tools)
            promise.fulfill()
        }
        APICalls().getToolRentals(employeeID: 9999) { toolsNimgs in
            XCTAssertNil(toolsNimgs)
            promise.fulfill()
        }
        wait(for: [promise], timeout: 15)
    }
    
    func testGetFIRtoken() {
        let promise = expectation(description: "Should get Firebase token for valid phone number")
        
        APICalls.getFIRidToken() { token in
            XCTAssertNotNil(token)
            promise.fulfill()
        }
        wait(for: [promise], timeout: 10)
    }
    
    func testExtendRental() {
        let promise = expectation(description: "Returns a JSON dictionary")
        let rentalExt = FieldActions.ToolRentalExtension(requestedBy: "Loyd_Christmas", toolType: "hammer", brand: "chinese", duration: "5")
        let wrongRental = FieldActions.ToolRentalExtension(requestedBy: "", toolType: "", brand: "", duration: "")
        promise.expectedFulfillmentCount = 2
        
        APICalls().extendRental(toolData: rentalExt) { success in
            XCTAssertNotNil(success)
            promise.fulfill()
        }
        APICalls().extendRental(toolData: wrongRental) { success in
            XCTAssertNotNil(success)
            promise.fulfill()
        }
        wait(for: [promise], timeout: 10)
    }
 
    func testGetJobNames() {
        let promise = expectation(description: "Returns with existing job names or Error")
        
        APICalls().getJobNames { (error, jobNames) in
            if error != nil {
                XCTFail("\(error)")
            }
            XCTAssertNotNil(jobNames)
            XCTAssertGreaterThan(jobNames!.count, 0)
            promise.fulfill()
        }
        wait(for: [promise], timeout: 10)
    }
    
    func testSetReq() {
        let promise = expectation(description: "Receives properly setup Http Request")
        
        APICalls().setupRequest(route: "jobs", method: "POST") { (req) in
            let url = URL(string: "\(APICalls.host)jobs")
            XCTAssertNotNil(req)
            XCTAssertNotNil(req.url)
            XCTAssertEqual(req.httpMethod, "POST")
            XCTAssertEqual(req.url, url)
            XCTAssertNotNil(req.allHTTPHeaderFields)
            promise.fulfill()
        }
        wait(for: [promise], timeout: 10)
    }
    
    func testStartSesh() {
        let promise = expectation(description: "Initiates sesh and comes back w/ json or error")
        let request = URLRequest(url: URL(string: APICalls.host)!)
        let wrongRequest = URLRequest(url: URL(string: "\(APICalls.host)/wrongDirection")!)
        
        APICalls().startSession(request: request, route: "host URL") { (json) in
            XCTAssertNotNil(json)
            promise.fulfill()
        }
        APICalls().startSession(request: wrongRequest, route: "wrong Request") { (json) in
            XCTAssertNotNil(json)
            promise.fulfill()
        }
        wait(for: [promise], timeout: 10)
    }
    
    func testParseJbs() {
        let validJbs = [
            [
                "name" : "Fullerton and Imperial", "poNumber" : "905499", "jobLocation" : [ ],
                "dates" : [[ "installDate" : "2019-07-14T15:00:00.000Z", "endDate" : "2019-07-20T00:00:00.000Z" ]]
            ],
            [
                "name" : "Fullerton and Imperial", "poNumber" : "905499", "jobLocation" : [ ],
                "dates" : [[ "installDate" : "2019-07-14T15:00:00.000Z", "endDate" : "2019-07-20T00:00:00.000Z" ]]
            ]
        ]
        let parsedJobs = APICalls().parseJobs(from: NSArray(array: validJbs) )
        
        XCTAssertNotNil(parsedJobs)
        XCTAssertNotNil(parsedJobs[0])
        XCTAssertNotNil(parsedJobs[1])
        XCTAssertEqual(parsedJobs[0].jobName, "\(validJbs[0]["name"]!)")
        XCTAssertEqual(parsedJobs[0].poNumber, "\(validJbs[0]["poNumber"]!)")
    }
    
    func testParsetORs() {
        let tmOff = [
            [
             "end" : "2019-04-13T18:33:040Z", "start" : "2019-04-12T18:33:040Z", "username" : "GarciaMiguel", "signedDate" : "2019-04-11T18:33:25.097Z", "shiftHours" : "9-5", "employeeID" : "9758", "department" : "shop", "signaturePath" : "timeOffRequests/GarciaMiguel-Apr 12, 2019.jpg"
            ]
        ]
        
        let timeOffReqs = APICalls().parseTORS(from: NSArray(array: tmOff) )
        XCTAssertNotNil(timeOffReqs)
        XCTAssertNotNil(timeOffReqs[0])
        XCTAssertEqual(timeOffReqs[0].username, "\(tmOff[0]["username"]!)")
    }
    
    func test

}
