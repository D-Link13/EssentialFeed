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
  
  func test_load_deliversImagesWhenCacheIsLessThanSevenDaysOld() {
    let fixedCurrentDate = Date()
    let (store, sut) = makeSUT { fixedCurrentDate }
    let feedImages = uniqueFeedImages()
    let dateLessThenSevenDaysOld = fixedCurrentDate.adding(days: -7).adding(seconds: 1)
    
    expect(sut, toCompleteWith: .success(feedImages.models)) {
      store.completeRetrievalWith(cachedFeed: feedImages.local, timestamp: dateLessThenSevenDaysOld)
    }
  }
  
  func test_load_deliversNoImagesWhenCacheIsSevenDaysOld() {
    let fixedCurrentDate = Date()
    let (store, sut) = makeSUT { fixedCurrentDate }
    let feedImages = uniqueFeedImages()
    let dateSevenDaysOld = fixedCurrentDate.adding(days: -7)
    
    expect(sut, toCompleteWith: .success([])) {
      store.completeRetrievalWith(cachedFeed: feedImages.local, timestamp: dateSevenDaysOld)
    }
  }
  
  func test_load_deliversNoImagesWhenCacheIsMoreThanSevenDaysOld() {
    let fixedCurrentDate = Date()
    let (store, sut) = makeSUT { fixedCurrentDate }
    let feedImages = uniqueFeedImages()
    let dateMoreThanSevenDaysOld = fixedCurrentDate.adding(days: -7).adding(seconds: -1)
    
    expect(sut, toCompleteWith: .success([])) {
      store.completeRetrievalWith(cachedFeed: feedImages.local, timestamp: dateMoreThanSevenDaysOld)
    }
  }
  
  func test_load_hasNoSideEffectsOnRetrievalFailure() {
    let (store, sut) = makeSUT()
    
    sut.load() { _ in }
    store.completeRetrieval(with: anyNSError())
    
    XCTAssertEqual(store.receivedMessages, [.retrieve])
  }
  
  func test_load_doesNotDeleteCacheOnEmptyCache() {
    let (store, sut) = makeSUT()
    
    sut.load() { _ in }
    store.completeRetrievalWithEmptyCache()
    
    XCTAssertEqual(store.receivedMessages, [.retrieve])
  }
  
  func test_load_doesNotDeleteCacheWhenItIsLessThanSevenDaysOld() {
    let fixedCurrentDate = Date()
    let (store, sut) = makeSUT { fixedCurrentDate }
    let feedImages = uniqueFeedImages()
    let dateLessThenSevenDaysOld = fixedCurrentDate.adding(days: -7).adding(seconds: 1)
    
    sut.load { _ in }
    store.completeRetrievalWith(cachedFeed: feedImages.local, timestamp: dateLessThenSevenDaysOld)
    
    XCTAssertEqual(store.receivedMessages, [.retrieve])
  }
  
  func test_load_deletesCacheWhenItIsSevenDaysOld() {
    let fixedCurrentDate = Date()
    let (store, sut) = makeSUT { fixedCurrentDate }
    let feedImages = uniqueFeedImages()
    let dateSevenDaysOld = fixedCurrentDate.adding(days: -7)
    
    sut.load { _ in }
    store.completeRetrievalWith(cachedFeed: feedImages.local, timestamp: dateSevenDaysOld)
    
    XCTAssertEqual(store.receivedMessages, [.retrieve, .deleteCachedFeed])
  }
  
  func test_load_deletesCacheWhenItIsMoreThanSevenDaysOld() {
    let fixedCurrentDate = Date()
    let (store, sut) = makeSUT { fixedCurrentDate }
    let feedImages = uniqueFeedImages()
    let dateMoreThanSevenDaysOld = fixedCurrentDate.adding(days: -7).adding(seconds: -1)
    
    sut.load { _ in }
    store.completeRetrievalWith(cachedFeed: feedImages.local, timestamp: dateMoreThanSevenDaysOld)
    
    XCTAssertEqual(store.receivedMessages, [.retrieve, .deleteCachedFeed])
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

private extension Date {
  func adding(days: Int) -> Date {
    return Calendar(identifier: .gregorian).date(byAdding: .day, value: days, to: self)!
  }
  
  func adding(seconds: TimeInterval) -> Date {
    return self + seconds
  }
}
