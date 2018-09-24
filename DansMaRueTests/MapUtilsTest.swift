//
//  MapUtilsTest.swift
//  DansMaRueTests
//
//  Created by Xavier NOEL on 07/02/2018.
//  Copyright © 2018 VilleDeParis. All rights reserved.
//

import XCTest
@testable import DansMaRue

class MapUtilsTest: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testBoroughLabel() {
        XCTAssertEqual(MapsUtils.boroughLabel(postalCode: "75001"), "1 er")
        XCTAssertEqual(MapsUtils.boroughLabel(postalCode: "75002"), "2 ème")
        XCTAssertEqual(MapsUtils.boroughLabel(postalCode: "75010"), "10 ème")
        XCTAssertEqual(MapsUtils.boroughLabel(postalCode: "75020"), "20 ème")
        XCTAssertEqual(MapsUtils.boroughLabel(postalCode: "44000"), "44000")

    }
    
    func testFullAddressParis()  {
        MapsUtils.addressLabel = "227 rue de Bercy"
        MapsUtils.postalCode = "75012"
        MapsUtils.locality = "Paris 12E Arrondissement"
        XCTAssertEqual(MapsUtils.fullAddress(), "227 rue de Bercy, 75012 Paris")
    }
    
    func testFullAddressHorsParis()  {
        MapsUtils.addressLabel = "68 Boulevard Marcel Paul"
        MapsUtils.postalCode = "44800"
        MapsUtils.locality = "Saint Herblain"
        XCTAssertEqual(MapsUtils.fullAddress(), "68 Boulevard Marcel Paul, 44800 Saint Herblain")
    }
    
    func testGetStreetAddress() {
        XCTAssertEqual(MapsUtils.getStreetAddress(address: "227 rue de Bercy, 75012 Paris"), "227 rue de Bercy, ")
        XCTAssertEqual(MapsUtils.getStreetAddress(address: "68 Boulevard Marcel Paul, 44800 Saint Herblain"), "")
    }
    
    func testGetPostalCode() {
        XCTAssertEqual(MapsUtils.getPostalCode(address: "227 rue de Bercy, 75012 Paris"), "75012")
        XCTAssertEqual(MapsUtils.getPostalCode(address: "68 Boulevard Marcel Paul, 44800 Saint Herblain"), "")

    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
    
}
