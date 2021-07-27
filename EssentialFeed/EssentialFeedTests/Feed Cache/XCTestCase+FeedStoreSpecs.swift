//
//  XCTestCase+FeedStoreSpecs.swift
//  EssentialFeedTests
//
//  Created by Dmitry Tsurkan on 27.07.2021.
//

import XCTest
import EssentialFeed

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
