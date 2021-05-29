//
//  CacheFeedUseCaseTests.swift
//  EssentialFeedTests
//
//  Created by Dmitry Tsurkan on 28.05.2021.
//

import XCTest
import EssentialFeed

class LocalFeedLoader {
  private var store: FeedStore
  
  init(store: FeedStore) {
    self.store = store
  }
  
  func save(_ items: [FeedItem]) {
    store.deleteCachedFeed() { [weak self] error in
      if error == nil {
        self?.store.insert(items: items)
      }
    }
  }
}

class FeedStore {
  typealias DeleteCompletion = (Error?) -> Void
  
  var deleteCachedFeedCallCount = 0
  var deleteCompletions: [DeleteCompletion] = []
  var insertCallCount = 0
  
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
  
  func insert(items: [FeedItem]) {
    insertCallCount += 1
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
    
    XCTAssertEqual(store.insertCallCount, 0)
  }
  
  func test_save_requestsInsetionOnDeletionSuccessful() {
    let (store, sut) = makeSUT()
    
    sut.save([uniqueItem(), uniqueItem()])
    store.completeDeletionSuccessfully()
    
    XCTAssertEqual(store.insertCallCount, 1)
  }
  
  // MARK: - Helpers
  
  func makeSUT(file: StaticString = #filePath, line: UInt = #line) -> (store: FeedStore, sut: LocalFeedLoader) {
    let store = FeedStore()
    let sut = LocalFeedLoader(store: store)
    trackForMemoryLeaks(store, file: file, line: line)
    trackForMemoryLeaks(sut, file: file, line: line)
    return (store, sut)
  }
  
  func uniqueItem() -> FeedItem {
    return FeedItem(id: UUID(), description: "any", location: "any", imageUrl: anyURL())
  }
  
}
