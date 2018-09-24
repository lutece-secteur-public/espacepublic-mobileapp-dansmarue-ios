//
//  DansMaRueTests.swift
//  DansMaRueTests
//
//  Created by NTDC-Showroom on 16/03/2017.
//  Copyright © 2017 VilleDeParis. All rights reserved.
//

import XCTest

@testable import DansMaRue

class DansMaRueTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testServiceFaitEmail() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        XCTAssertEqual("john.doe@localhost.fr".isMailServiceFait(), false)
        XCTAssertEqual("john.doe@paris.fr".isMailServiceFait(), true)
        XCTAssertEqual("john.doe@derichebourg.com".isMailServiceFait(), true)
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
    
}
