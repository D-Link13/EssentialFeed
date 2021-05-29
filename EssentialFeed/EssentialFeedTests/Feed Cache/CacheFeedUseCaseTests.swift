//
//  CacheFeedUseCaseTests.swift
//  EssentialFeedTests
//
//  Created by Dmitry Tsurkan on 28.05.2021.
//

import XCTest
import EssentialFeed

class LocalFeedLoader {
  typealias CurrentDateProvider = () -> Date
  
  private let currentDate: CurrentDateProvider
  private let store: FeedStore
  
  init(store: FeedStore, currentDate: @escaping CurrentDateProvider) {
    self.store = store
    self.currentDate = currentDate
  }
  
  func save(_ items: [FeedItem]) {
    store.deleteCachedFeed() { [weak self] error in
      guard let self = self else { return }
      if error == nil {
        self.store.insert(items: items, timestamp: self.currentDate())
      }
    }
  }
}

class FeedStore {
  typealias DeleteCompletion = (Error?) -> Void
  
  var deleteCachedFeedCallCount = 0
  var deleteCompletions: [DeleteCompletion] = []
  var insertions: [(items: [FeedItem], timestamp: Date)] = []
  
  func deleteCachedFeed(_ completion: @escaping DeleteCompletion) {
    deleteCachedFeedCallCount += 1
    deleteCompletions.append(completion)
  }
  
  func completeDeletion(with error: Error, at index: Int = 0) {
    deleteCompletions[index](error)
  }
  
  func completeDeletionSuccessfully(at index: Int = 0) {
    deleteCompletions[index](nil)
  }
  
  func insert(items: [FeedItem], timestamp: Date) {
    insertions.append((items, timestamp))
  }
}

class CacheFeedUseCaseTests: XCTestCase {
  
  func test_init_doesNotDeleteCacheUponCreation() {
    XCTAssertEqual(makeSUT().store.deleteCachedFeedCallCount, 0)
  }
  
  func test_save_requestsCacheDeletionOnce() {
    let (store, sut) = makeSUT()
    
    sut.save([uniqueItem(), uniqueItem()])
    
    XCTAssertEqual(store.deleteCachedFeedCallCount, 1)
  }
  
  func test_save_doesNotRequestInsertionOnDeletionFailure() {
    let (store, sut) = makeSUT()
    
    sut.save([uniqueItem(), uniqueItem()])
    store.completeDeletion(with: anyNSError())
    
    XCTAssertEqual(store.insertions.count, 0)
  }
  
  func test_save_requestsInsetionWithtimestampOnDeletionSuccessful() {
    let timestamp = Date()
    let (store, sut) = makeSUT(currentDate: { timestamp })
    let items = [uniqueItem(), uniqueItem()]
    
    sut.save(items)
    store.completeDeletionSuccessfully()
    
    XCTAssertEqual(store.insertions.count, 1)
    XCTAssertEqual(store.insertions[0].items, items)
    XCTAssertEqual(store.insertions[0].timestamp, timestamp)
  }
  
  // MARK: - Helpers
  
  func makeSUT(currentDate: @escaping () -> Date = Date.init, file: StaticString = #filePath, line: UInt = #line) -> (store: FeedStore, sut: LocalFeedLoader) {
    let store = FeedStore()
    let sut = LocalFeedLoader(store: store, currentDate: currentDate)
    trackForMemoryLeaks(store, file: file, line: line)
    trackForMemoryLeaks(sut, file: file, line: line)
    return (store, sut)
  }
  
  func uniqueItem() -> FeedItem {
    return FeedItem(id: UUID(), description: "any", location: "any", imageUrl: anyURL())
  }
  
}
