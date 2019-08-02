//
//  FieldAppTests.swift
//  FieldAppTests
//
//  Created by Kevin Bradbury on 9/19/17.
//  Copyright © 2017 Kevin Bradbury. All rights reserved.
//

import XCTest
import FirebaseCore
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

extension FieldAppTests {
    func testIfHostSet() {
        let testHost = "https://www.mb-test-server-01.de/"
        APICalls.getHostFromPList()
        
        XCTAssertEqual(testHost, APICalls.host, "Test Host name equal")
        XCTAssertNotNil(APICalls.host)
    }
    
    func checkFIRtoken() {
        var token = false
        APICalls().checkForToken(employeeID: "9999") { hasTkn in
            token = hasTkn
        }
        XCTAssertFalse(token)
        APICalls().checkForToken(employeeID: "200") { hasTkn in
            token = hasTkn
        }
        XCTAssertTrue(hasTkn)
    }
    
    func getJbInfo() {
        APICalls().fetchJobInfo(employeeID: "200") { (userJob, tmOff, holidays) in
            XCTAssertNotNil(userJob)
            XCTAssertNotNil(tmOff)
            XCTAssertNotNil(holidays)
        }
        APICalls().fetchJobInfo(employeeID: "9999") { (userJob, tmOff, holidays) in
            XCTFail("Doesnt find jbInfo for nonexistent employee")
        }
    }
}
