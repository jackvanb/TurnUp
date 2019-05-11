//
//  TurnUpTests.swift
//  TurnUpTests
//
//  Created by Jack Van Boening on 5/10/19.
//  Copyright © 2019 Jack Van Boening. All rights reserved.
//

import XCTest
@testable import TurnUp

class TurnUpTests: XCTestCase {

  override func setUp() {
      // Put setup code here. This method is called before the invocation of each test method in the class.
  }

  override func tearDown() {
      // Put teardown code here. This method is called after the invocation of each test method in the class.
  }

  func testExample() {
      // This is an example of a functional test case.
      // Use XCTAssert and related functions to verify your tests produce the correct results.
  }

  func testEventInit() {
    let mockEvent = Event.init(name: "Party", organization: "PKP", date: "4/20/19", address: "613 Gayley", count: 69)
    
    XCTAssertNotNil(mockEvent)
    
  }

  func testPerformanceExample() {
      // This is an example of a performance test case.
      self.measure {
          // Put the code you want to measure the time of here.
      }
  }

}
