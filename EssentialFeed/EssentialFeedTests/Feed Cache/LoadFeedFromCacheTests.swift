//
//  LoadFeedFromCacheTests.swift
//  EssentialFeedTests
//
//  Created by Dmitry Tsurkan on 07.06.2021.
//

import XCTest
import EssentialFeed

class LoadFeedFromCacheTests: XCTestCase {

  func test_init_doesNotMessageStoreUponCreation() {
    let (store, _) = makeSUT()
    
    XCTAssertEqual(store.receivedMessages, [])
  }
  
  func test_load_callsRetrieveFromStore() {
    let (store, sut) = makeSUT()
    
    sut.load() { _ in }
    
    XCTAssertEqual(store.receivedMessages, [.retrieve])
  }
  
  func test_load_failsOnStoreRetrieveFailure() {
    let (store, sut) = makeSUT()
    let retrievalError = anyNSError()
    let exp = expectation(description: "Wait till load completes")
    
    var capturedError: Error?
    sut.load { error in
      capturedError = error
      exp.fulfill()
    }
    store.completeRetrieval(with: retrievalError)
    
    wait(for: [exp], timeout: 1.0)
    XCTAssertEqual(capturedError as NSError?, retrievalError)
  }
  
  // MARK: - Helpers
  
  private func makeSUT(currentDate: @escaping () -> Date = Date.init, file: StaticString = #filePath, line: UInt = #line) -> (store: FeedStoreSpy, sut: LocalFeedLoader) {
    let store = FeedStoreSpy()
    let sut = LocalFeedLoader(store: store, currentDate: currentDate)
    trackForMemoryLeaks(store, file: file, line: line)
    trackForMemoryLeaks(sut, file: file, line: line)
    return (store, sut)
  }
  
}
