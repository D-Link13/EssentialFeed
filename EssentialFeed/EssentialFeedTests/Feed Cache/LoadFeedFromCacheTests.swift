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
    
    expect(sut, toCompleteWith: .failure(retrievalError)) {
      store.completeRetrieval(with: retrievalError)
    }
  }
  
  func test_load_deliversNoImagesOnEmptyCache() {
    let (store, sut) = makeSUT()
    
    expect(sut, toCompleteWith: .success([])) {
      store.completeRetrievalWithEmptyCache()
    }
  }
  
  // MARK: - Helpers
  
  private func makeSUT(currentDate: @escaping () -> Date = Date.init, file: StaticString = #filePath, line: UInt = #line) -> (store: FeedStoreSpy, sut: LocalFeedLoader) {
    let store = FeedStoreSpy()
    let sut = LocalFeedLoader(store: store, currentDate: currentDate)
    trackForMemoryLeaks(store, file: file, line: line)
    trackForMemoryLeaks(sut, file: file, line: line)
    return (store, sut)
  }
  
  private func expect(_ sut: LocalFeedLoader, toCompleteWith expectedResult: LocalFeedLoader.LoadResult, when action: () -> Void, file: StaticString = #filePath, line: UInt = #line) {
    let exp = expectation(description: "Wait till load completes")
    sut.load { receivedResult in
      switch (receivedResult, expectedResult) {
      case (.success(let receivedImages), .success(let expectedImages)):
        XCTAssertEqual(receivedImages, expectedImages, file: file, line: line)
      case (.failure(let receivedError as NSError), .failure(let expectedError as NSError)):
        XCTAssertEqual(receivedError, expectedError, file: file, line: line)
      default:
        XCTFail("Expected result: \(expectedResult), but received result: \(receivedResult) instead.", file: file, line: line)
      }
      exp.fulfill()
    }
    action()

    wait(for: [exp], timeout: 1.0)
  }
  
}
