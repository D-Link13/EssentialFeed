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
  
  func test_load_deliversImagesWhenCacheIsNotExpired() {
    let fixedCurrentDate = Date()
    let (store, sut) = makeSUT { fixedCurrentDate }
    let feedImages = uniqueFeedImages()
    let notExpiredTimestamp = fixedCurrentDate.minusCacheMaxAge().adding(seconds: 1)
    
    expect(sut, toCompleteWith: .success(feedImages.models)) {
      store.completeRetrievalWith(cachedFeed: feedImages.local, timestamp: notExpiredTimestamp)
    }
  }
  
  func test_load_deliversNoImagesWhenCacheIsExpiring() {
    let fixedCurrentDate = Date()
    let (store, sut) = makeSUT { fixedCurrentDate }
    let feedImages = uniqueFeedImages()
    let expiringTimestamp = fixedCurrentDate.minusCacheMaxAge()
    
    expect(sut, toCompleteWith: .success([])) {
      store.completeRetrievalWith(cachedFeed: feedImages.local, timestamp: expiringTimestamp)
    }
  }
  
  func test_load_deliversNoImagesWhenCacheIsExpired() {
    let fixedCurrentDate = Date()
    let (store, sut) = makeSUT { fixedCurrentDate }
    let feedImages = uniqueFeedImages()
    let expiredTimestamp = fixedCurrentDate.minusCacheMaxAge().adding(seconds: -1)
    
    expect(sut, toCompleteWith: .success([])) {
      store.completeRetrievalWith(cachedFeed: feedImages.local, timestamp: expiredTimestamp)
    }
  }
  
  func test_load_hasNoSideEffectsOnRetrievalFailure() {
    let (store, sut) = makeSUT()
    
    sut.load() { _ in }
    store.completeRetrieval(with: anyNSError())
    
    XCTAssertEqual(store.receivedMessages, [.retrieve])
  }
  
  func test_load_hasNoSideEffectsOnEmptyCache() {
    let (store, sut) = makeSUT()
    
    sut.load() { _ in }
    store.completeRetrievalWithEmptyCache()
    
    XCTAssertEqual(store.receivedMessages, [.retrieve])
  }
  
  func test_load_hasNoSideEffectsOnNonExpiredCache() {
    let fixedCurrentDate = Date()
    let (store, sut) = makeSUT { fixedCurrentDate }
    let feedImages = uniqueFeedImages()
    let nonExpiredTimestamp = fixedCurrentDate.minusCacheMaxAge().adding(seconds: 1)
    
    sut.load { _ in }
    store.completeRetrievalWith(cachedFeed: feedImages.local, timestamp: nonExpiredTimestamp)
    
    XCTAssertEqual(store.receivedMessages, [.retrieve])
  }
  
  func test_load_hasNoSideEffectsExpiringCache() {
    let fixedCurrentDate = Date()
    let (store, sut) = makeSUT { fixedCurrentDate }
    let feedImages = uniqueFeedImages()
    let expiringTimestamp = fixedCurrentDate.minusCacheMaxAge()
    
    sut.load { _ in }
    store.completeRetrievalWith(cachedFeed: feedImages.local, timestamp: expiringTimestamp)
    
    XCTAssertEqual(store.receivedMessages, [.retrieve])
  }
  
  func test_load_hasNoSideEffectsOnExpiredCache() {
    let fixedCurrentDate = Date()
    let (store, sut) = makeSUT { fixedCurrentDate }
    let feedImages = uniqueFeedImages()
    let expiredTimestamp = fixedCurrentDate.minusCacheMaxAge().adding(seconds: -1)
    
    sut.load { _ in }
    store.completeRetrievalWith(cachedFeed: feedImages.local, timestamp: expiredTimestamp)
    
    XCTAssertEqual(store.receivedMessages, [.retrieve])
  }
  
  func test_load_doesNotDeliverResultAfterDeallocation() {
    let store = FeedStoreSpy()
    var sut: LocalFeedLoader? = LocalFeedLoader(store: store, currentDate: Date.init)
    
    var receivedResults = [LocalFeedLoader.LoadResult]()
    sut?.load { receivedResults.append($0) }
    sut = nil
    store.completeRetrievalWithEmptyCache()
    
    XCTAssertTrue(receivedResults.isEmpty)
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
  
  private func uniqueFeedImage() -> FeedImage {
    return FeedImage(id: UUID(), description: "any", location: "any", url: anyURL())
  }
  
  private func uniqueFeedImages() -> (models: [FeedImage], local: [LocalFeedImage]) {
    let models = [uniqueFeedImage(), uniqueFeedImage()]
    let local = models.map { LocalFeedImage(id: $0.id, description: $0.description, location: $0.location, url: $0.url) }
    return (models, local)
  }
  
}
