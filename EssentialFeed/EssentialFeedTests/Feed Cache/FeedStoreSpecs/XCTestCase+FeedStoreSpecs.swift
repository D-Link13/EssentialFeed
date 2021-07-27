//
//  XCTestCase+FeedStoreSpecs.swift
//  EssentialFeedTests
//
//  Created by Dmitry Tsurkan on 27.07.2021.
//

import XCTest
import EssentialFeed

extension FeedStoreSpecs where Self: XCTestCase {
  
  func assertThatRetrieveDeliversEmptyOnEmptyCache(on sut: FeedStore, file: StaticString = #file, line: UInt = #line) {
    expect(sut, toRetrieve: .empty, file: file, line: line)
  }
  
  func assertThatRetrieveHasNoSideEffectsOnEmptyCache(on sut: FeedStore, file: StaticString = #file, line: UInt = #line) {
    expect(sut, toRetrieveTwice: .empty, file: file, line: line)
  }
  
  func assertThatRetrieveDeliversFoundValuesOnNonEmptyCache(on sut: FeedStore, file: StaticString = #file, line: UInt = #line) {
    let feed = uniqueFeedImages().local
    let timestamp = Date()
    
    insert((feed, timestamp), to: sut)
    
    expect(sut, toRetrieve: .found(feed, timestamp), file: file, line: line)
  }
  
  func assertThatRetrieveHasNoSideEffectsOnNonEmptyCache(on sut: FeedStore, file: StaticString = #file, line: UInt = #line) {
    let feed = uniqueFeedImages().local
    let timestamp = Date()
    
    insert((feed, timestamp), to: sut)
    
    expect(sut, toRetrieveTwice: .found(feed, timestamp), file: file, line: line)
  }
  
  func assertThatInsertDeliversNoErrorOnEmptyCache(on sut: FeedStore, file: StaticString = #file, line: UInt = #line) {
    let insertionError = insert((uniqueFeedImages().local, Date()), to: sut)
    
    XCTAssertNil(insertionError, "Expected to insert cache successfully", file: file, line: line)
  }
  
  func assertThatInsertDeliversNoErrorOnNonEmptyCache(on sut: FeedStore, file: StaticString = #file, line: UInt = #line) {
    insert((uniqueFeedImages().local, Date()), to: sut)
    
    let insertionError = insert((uniqueFeedImages().local, Date()), to: sut)
    
    XCTAssertNil(insertionError, "Expected to override cache successfully", file: file, line: line)
  }
  
  func assertThatInsertOverridesPreviouslyInsertedCacheValues(on sut: FeedStore, file: StaticString = #file, line: UInt = #line) {
    insert((uniqueFeedImages().local, Date()), to: sut)
    
    let latestFeed = uniqueFeedImages().local
    let latestTimestamp = Date()
    insert((latestFeed, latestTimestamp), to: sut)
    
    expect(sut, toRetrieve: .found(latestFeed, latestTimestamp), file: file, line: line)
  }
  
  func assertThatDeleteDeliversNoErrorOnEmptyCache(on sut: FeedStore, file: StaticString = #file, line: UInt = #line) {
    let deletionError = deleteCache(from: sut)
    
    XCTAssertNil(deletionError, "Expected empty cache deletion to succeed", file: file, line: line)
  }
  
  func assertThatDeleteHasNoSideEffectsOnEmptyCache(on sut: FeedStore, file: StaticString = #file, line: UInt = #line) {
    deleteCache(from: sut)
    
    expect(sut, toRetrieve: .empty, file: file, line: line)
  }
  
  func assertThatDeleteDeliversNoErrorOnNonEmptyCache(on sut: FeedStore, file: StaticString = #file, line: UInt = #line) {
    insert((uniqueFeedImages().local, Date()), to: sut)
    
    let deletionError = deleteCache(from: sut)
    
    XCTAssertNil(deletionError, "Expected non-empty cache deletion to succeed", file: file, line: line)
  }
  
  func assertThatDeleteEmptiesPreviouslyInsertedCache(on sut: FeedStore, file: StaticString = #file, line: UInt = #line) {
    insert((uniqueFeedImages().local, Date()), to: sut)
    
    deleteCache(from: sut)
    
    expect(sut, toRetrieve: .empty, file: file, line: line)
  }
  
  func assertThatSideEffectsRunSerially(on sut: FeedStore, file: StaticString = #file, line: UInt = #line) {
    var completedOperationsInOrder = [XCTestExpectation]()
    
    let op1 = expectation(description: "Operation 1")
    sut.insert(uniqueFeedImages().local, timestamp: Date()) { _ in
      completedOperationsInOrder.append(op1)
      op1.fulfill()
    }
    
    let op2 = expectation(description: "Operation 2")
    sut.deleteCachedFeed { _ in
      completedOperationsInOrder.append(op2)
      op2.fulfill()
    }
    
    let op3 = expectation(description: "Operation 3")
    sut.insert(uniqueFeedImages().local, timestamp: Date()) { _ in
      completedOperationsInOrder.append(op3)
      op3.fulfill()
    }
    
    waitForExpectations(timeout: 5.0)
    
    XCTAssertEqual(completedOperationsInOrder, [op1, op2, op3], "Expected side-effects to run serially but operations finished in the wrong order", file: file, line: line)
  }
  
  func assertThatRetrieveRunsAsyncronusly(on sut: FeedStore, file: StaticString = #file, line: UInt = #line) {
    var completedOperations = [XCTestExpectation]()
    let exp = expectation(description: "Wait until retrieve completes")
    
    sut.retrieve { _ in
      completedOperations.append(exp)
      exp.fulfill()
    }

    XCTAssertEqual(completedOperations.count, 0, "Expected retrieve not to block further code execution (asyncronous)", file: file, line: line)
    wait(for: [exp], timeout: 3.0)
    XCTAssertEqual(completedOperations, [exp], "Expected retrieve to complete after timeout", file: file, line: line)
  }
  
  func assertThatInsertRunsAsyncronusly(on sut: FeedStore, file: StaticString = #file, line: UInt = #line) {
    var completedOperations = [XCTestExpectation]()
    let exp = expectation(description: "Wait until insert completes")
    
    sut.insert(uniqueFeedImages().local, timestamp: Date()) { _ in
      completedOperations.append(exp)
      exp.fulfill()
    }

    XCTAssertEqual(completedOperations.count, 0, "Expected insert not to block further code execution (asyncronous)", file: file, line: line)
    wait(for: [exp], timeout: 3.0)
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
    wait(for: [exp], timeout: 3.0)
    XCTAssertEqual(completedOperations, [exp], "Expected delete to complete after timeout", file: file, line: line)
  }
  
}

extension FeedStoreSpecs where Self: XCTestCase {
  
  @discardableResult
  func insert(_ insertion: (feed: [LocalFeedImage], timestamp: Date), to sut: FeedStore) -> Error? {
    let exp = expectation(description: "Wait until insert is completed")
    
    var capturedError: Error?
    sut.insert(insertion.feed, timestamp: insertion.timestamp) { insertionError in
      capturedError = insertionError
      exp.fulfill()
    }
    wait(for: [exp], timeout: 1.0)
    return capturedError
  }
  
  @discardableResult
  func deleteCache(from sut: FeedStore) -> Error? {
    let exp = expectation(description: "Wait until delete is completed")
    
    var capturedError: Error?
    sut.deleteCachedFeed { deletionError in
      capturedError = deletionError
      exp.fulfill()
    }
    wait(for: [exp], timeout: 1.0)
    return capturedError
  }
  
  func expect(_ sut: FeedStore, toRetrieveTwice expectedResult: RetrievalResult, file:StaticString = #filePath, line: UInt = #line) {
    expect(sut, toRetrieve: expectedResult, file: file, line: line)
    expect(sut, toRetrieve: expectedResult, file: file, line: line)
  }
  
  func expect(_ sut: FeedStore, toRetrieve expectedResult: RetrievalResult, file:StaticString = #filePath, line: UInt = #line) {
    let exp = expectation(description: "Wait till retrieve completes")
    sut.retrieve { actualResult in
      switch (expectedResult, actualResult) {
      case (.empty, .empty),
           (.failure, .failure):
        break
      case let (.found(expectedFeed, expectedTimestamp), .found(actualFeed, actualTimestamp)):
        XCTAssertEqual(expectedFeed, actualFeed, file: file, line: line)
        XCTAssertEqual(expectedTimestamp, actualTimestamp, file: file, line: line)
      default: XCTFail("Expected to restrieve \(expectedResult) result, got result: \(actualResult) instead", file: file, line: line)
      }
      exp.fulfill()
    }
    wait(for: [exp], timeout: 1.0)
  }
}
