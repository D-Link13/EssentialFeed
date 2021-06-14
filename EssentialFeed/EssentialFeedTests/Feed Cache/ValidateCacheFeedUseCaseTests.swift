//
//  ValidateCacheFeedUseCaseTests.swift
//  EssentialFeedTests
//
//  Created by Dmitry Tsurkan on 10.06.2021.
//

import XCTest
import EssentialFeed

class ValidateCacheFeedUseCaseTests: XCTestCase {
  
  func test_init_doesNotMessageStoreUponCreation() {
    let (store, _) = makeSUT()
    
    XCTAssertEqual(store.receivedMessages, [])
  }
  
  func test_validateCache_deletesCacheOnRetrievalFailure() {
    let (store, sut) = makeSUT()
    
    sut.validateCache()
    store.completeRetrieval(with: anyNSError())
    
    XCTAssertEqual(store.receivedMessages, [.retrieve, .deleteCachedFeed])
  }
  
  func test_validateCache_doesNotDeleteOnEmptyCache() {
    let (store, sut) = makeSUT()
    
    sut.validateCache()
    store.completeRetrievalWithEmptyCache()
    
    XCTAssertEqual(store.receivedMessages, [.retrieve])
  }
  
  func test_validateCache_doesNotDeleteOnIsNotExpiredCache() {
    let fixedCurrentDate = Date()
    let (store, sut) = makeSUT { fixedCurrentDate }
    let feedImages = uniqueFeedImages()
    let notExpiredTimestamp = fixedCurrentDate.minusCacheMaxAge().adding(seconds: 1)
    
    sut.validateCache()
    store.completeRetrievalWith(cachedFeed: feedImages.local, timestamp: notExpiredTimestamp)
    
    XCTAssertEqual(store.receivedMessages, [.retrieve])
  }
  
  func test_validateCache_deletesOnExpiringCache() {
    let fixedCurrentDate = Date()
    let (store, sut) = makeSUT { fixedCurrentDate }
    let feedImages = uniqueFeedImages()
    let expiringTimestamp = fixedCurrentDate.minusCacheMaxAge()
    
    sut.validateCache()
    store.completeRetrievalWith(cachedFeed: feedImages.local, timestamp: expiringTimestamp)
    
    XCTAssertEqual(store.receivedMessages, [.retrieve, .deleteCachedFeed])
  }
  
  func test_validateCache_deletesOnExpiredCache() {
    let fixedCurrentDate = Date()
    let (store, sut) = makeSUT { fixedCurrentDate }
    let feedImages = uniqueFeedImages()
    let expiredTimestamp = fixedCurrentDate.minusCacheMaxAge().adding(seconds: -1)
    
    sut.validateCache()
    store.completeRetrievalWith(cachedFeed: feedImages.local, timestamp: expiredTimestamp)
    
    XCTAssertEqual(store.receivedMessages, [.retrieve, .deleteCachedFeed])
  }
  
  func test_validateCache_doesNotDeleteCacheOnInstanceDeallocation() {
    let store = FeedStoreSpy()
    var sut: LocalFeedLoader? = LocalFeedLoader(store: store, currentDate: Date.init)
    
    sut?.validateCache()
    
    sut = nil
    store.completeRetrieval(with: anyNSError())
    
    XCTAssertEqual(store.receivedMessages, [.retrieve])
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
