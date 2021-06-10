//
//  CacheFeedUseCaseTests.swift
//  EssentialFeedTests
//
//  Created by Dmitry Tsurkan on 28.05.2021.
//

import XCTest
import EssentialFeed

class CacheFeedUseCaseTests: XCTestCase {
  
  func test_init_doesNotMessageStoreUponCreation() {
    let (store, _) = makeSUT()
    
    XCTAssertEqual(store.receivedMessages, [])
  }
  
  func test_save_requestsCacheDeletionOnce() {
    let (store, sut) = makeSUT()
    
    sut.save(uniqueFeedImages().models) { _ in }
    
    XCTAssertEqual(store.receivedMessages, [.deleteCachedFeed])
  }
  
  func test_save_doesNotRequestInsertionOnDeletionFailure() {
    let (store, sut) = makeSUT()
    
    sut.save(uniqueFeedImages().models) { _ in }
    store.completeDeletion(with: anyNSError())
    
    XCTAssertEqual(store.receivedMessages, [.deleteCachedFeed])
  }
  
  func test_save_requestsInsetionWithtimestampOnDeletionSuccessful() {
    let timestamp = Date()
    let (store, sut) = makeSUT(currentDate: { timestamp })
    let items = uniqueFeedImages()
    
    sut.save(items.models) { _ in }
    store.completeDeletionSuccessfully()
    
    XCTAssertEqual(store.receivedMessages, [.deleteCachedFeed, .insert(items: items.local, timestamp: timestamp)])
  }
  
  func test_save_failsOnDeletionFailure() {
    let (store, sut) = makeSUT()
    let deletionError = anyNSError()
    
    expect(sut, toCompleteWith: deletionError, when: {
      store.completeDeletion(with: deletionError)
    })
  }
  
  func test_save_failsOnInsertionFailure() {
    let (store, sut) = makeSUT()
    let insertionError = anyNSError()
    
    expect(sut, toCompleteWith: insertionError, when: {
      store.completeDeletionSuccessfully()
      store.completeInsertion(with: insertionError)
    })
  }
  
  func test_save_succeedsOnCacheInsertionSuccess() {
    let (store, sut) = makeSUT()
    
    expect(sut, toCompleteWith: nil, when: {
      store.completeDeletionSuccessfully()
      store.completeInsertionSuccessfully()
    })
  }
  
  func test_save_doesNotDeliverDeletionErrorAfterSUTisDeallocated() {
    let store = FeedStoreSpy()
    var sut: LocalFeedLoader? = LocalFeedLoader(store: store, currentDate: Date.init)
    
    var receivedErrors: [LocalFeedLoader.SaveResult] = []
    sut?.save(uniqueFeedImages().models, completion: { receivedErrors.append($0) })
    
    sut = nil
    store.completeDeletion(with: anyNSError())
    
    XCTAssertTrue(receivedErrors.isEmpty)
  }
  
  func test_save_doesNotDeliverInsertionErrorAfterSUTisDeallocated() {
    let store = FeedStoreSpy()
    var sut: LocalFeedLoader? = LocalFeedLoader(store: store, currentDate: Date.init)
    
    var receivedErrors: [LocalFeedLoader.SaveResult] = []
    sut?.save(uniqueFeedImages().models, completion: { receivedErrors.append($0) })
    
    store.completeDeletionSuccessfully()
    sut = nil
    store.completeInsertion(with: anyNSError())
    
    XCTAssertTrue(receivedErrors.isEmpty)
  }
  
  // MARK: - Helpers
  
  private func makeSUT(currentDate: @escaping () -> Date = Date.init, file: StaticString = #filePath, line: UInt = #line) -> (store: FeedStoreSpy, sut: LocalFeedLoader) {
    let store = FeedStoreSpy()
    let sut = LocalFeedLoader(store: store, currentDate: currentDate)
    trackForMemoryLeaks(store, file: file, line: line)
    trackForMemoryLeaks(sut, file: file, line: line)
    return (store, sut)
  }
  
  private func expect(_ sut: LocalFeedLoader, toCompleteWith expectedError: NSError?, when action: () -> (), file: StaticString = #filePath, line: UInt = #line) {
    let exp = expectation(description: "Wait until save completes")

    var receivedError: Error?
    sut.save(uniqueFeedImages().models) { error in
      receivedError = error
      exp.fulfill()
    }
    action()
    
    wait(for: [exp], timeout: 1.0)
    
    XCTAssertEqual(receivedError as NSError?, expectedError, file: file, line: line)
  }

}
