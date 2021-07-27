//
//  XCTestCase + AsynchronusFeedStoreSpecs.swift
//  EssentialFeedTests
//
//  Created by Ra Man on 27.07.2021.
//

import XCTest
import EssentialFeed

extension AsyncronusFeedStoreSpecs where Self: XCTestCase {
  func assertThatRetrieveRunsAsyncronusly(on sut: FeedStore, file: StaticString = #file, line: UInt = #line) {
    var operationFinished:Bool = false
    let exp = expectation(description: "Wait until retrieve completes")
    
    sut.retrieve { _ in
      operationFinished = true
      exp.fulfill()
    }

    XCTAssertEqual(operationFinished, false, "Expected retrieve not to block further code execution (asyncronous)", file: file, line: line)
    waitForExpectations(timeout: 10.0)
    XCTAssertEqual(operationFinished, true, "Expected retrieve to complete after timeout", file: file, line: line)
  }
  
  func assertThatInsertRunsAsyncronusly(on sut: FeedStore, file: StaticString = #file, line: UInt = #line) {
    var completedOperations = [XCTestExpectation]()
    let exp = expectation(description: "Wait until insert completes")
    
    sut.insert(uniqueFeedImages().local, timestamp: Date()) { _ in
      completedOperations.append(exp)
      exp.fulfill()
    }

    XCTAssertEqual(completedOperations.count, 0, "Expected insert not to block further code execution (asyncronous)", file: file, line: line)
    waitForExpectations(timeout: 10.0)
    XCTAssertEqual(completedOperations, [exp], "Expected insert to complete after timeout", file: file, line: line)
  }
  
  func assertThatDeleteRunsAsyncronusly(on sut: FeedStore, file: StaticString = #file, line: UInt = #line) {
    var completedOperations = [XCTestExpectation]()
    let exp = expectation(description: "Wait until delete completes")
    
    sut.deleteCachedFeed { _ in
      completedOperations.append(exp)
      exp.fulfill()
    }

    XCTAssertEqual(completedOperations.count, 0, "Expected delete not to block further code execution (asyncronous)", file: file, line: line)
    waitForExpectations(timeout: 10.0)
    XCTAssertEqual(completedOperations, [exp], "Expected delete to complete after timeout", file: file, line: line)
  }
}
