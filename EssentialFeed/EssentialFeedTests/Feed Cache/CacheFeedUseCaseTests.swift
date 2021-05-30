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
  
  func save(_ items: [FeedItem], completion: @escaping (Error?) -> Void) {
    store.deleteCachedFeed() { [weak self] error in
      guard let self = self else { return }
      if error == nil {
        self.store.insert(items: items, timestamp: self.currentDate(), completion: completion)
      } else {
        completion(error)
      }
    }
  }
  
}


class FeedStore {
  typealias DeleteCompletion = (Error?) -> Void
  typealias InsertCompletion = (Error?) -> Void
  
  var deleteCompletions: [DeleteCompletion] = []
  var insertCompletions: [InsertCompletion] = []
  private(set) var receivedMessages: [ReceivedMessage] = []
  
  enum ReceivedMessage: Equatable {
    case deleteCachedFeed
    case insert(items: [FeedItem], timestamp: Date)
  }
  
  func deleteCachedFeed(_ completion: @escaping DeleteCompletion) {
    deleteCompletions.append(completion)
    receivedMessages.append(.deleteCachedFeed)
  }
  
  func completeDeletion(with error: Error, at index: Int = 0) {
    deleteCompletions[index](error)
  }
  
  func completeDeletionSuccessfully(at index: Int = 0) {
    deleteCompletions[index](nil)
  }
  
  func insert(items: [FeedItem], timestamp: Date, completion: @escaping DeleteCompletion) {
    insertCompletions.append(completion)
    receivedMessages.append(.insert(items: items, timestamp: timestamp))
  }
  
  func completeInsertion(with error: Error, at index: Int = 0) {
    insertCompletions[index](error)
  }
  
  func completeInsertionSuccessfully(at index: Int = 0) {
    insertCompletions[index](nil)
  }
  
}


class CacheFeedUseCaseTests: XCTestCase {
  
  func test_init_doesNotMessageStoreUponCreation() {
    let (store, _) = makeSUT()
    
    XCTAssertEqual(store.receivedMessages, [])
  }
  
  func test_save_requestsCacheDeletionOnce() {
    let items = [uniqueItem(), uniqueItem()]
    let (store, sut) = makeSUT()
    
    sut.save(items) { _ in }
    
    XCTAssertEqual(store.receivedMessages, [.deleteCachedFeed])
  }
  
  func test_save_doesNotRequestInsertionOnDeletionFailure() {
    let (store, sut) = makeSUT()
    
    sut.save([uniqueItem(), uniqueItem()]) { _ in }
    store.completeDeletion(with: anyNSError())
    
    XCTAssertEqual(store.receivedMessages, [.deleteCachedFeed])
  }
  
  func test_save_requestsInsetionWithtimestampOnDeletionSuccessful() {
    let timestamp = Date()
    let (store, sut) = makeSUT(currentDate: { timestamp })
    let items = [uniqueItem(), uniqueItem()]
    
    sut.save(items) { _ in }
    store.completeDeletionSuccessfully()
    
    XCTAssertEqual(store.receivedMessages, [.deleteCachedFeed, .insert(items: items, timestamp: timestamp)])
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
  
  // MARK: - Helpers
  
  func makeSUT(currentDate: @escaping () -> Date = Date.init, file: StaticString = #filePath, line: UInt = #line) -> (store: FeedStore, sut: LocalFeedLoader) {
    let store = FeedStore()
    let sut = LocalFeedLoader(store: store, currentDate: currentDate)
    trackForMemoryLeaks(store, file: file, line: line)
    trackForMemoryLeaks(sut, file: file, line: line)
    return (store, sut)
  }
  
  func expect(_ sut: LocalFeedLoader, toCompleteWith expectedError: NSError?, when action: () -> (), file: StaticString = #filePath, line: UInt = #line) {
    let exp = expectation(description: "Wait until save completes")
    
    var receivedError: Error?
    sut.save([uniqueItem(), uniqueItem()]) { error in
      receivedError = error
      exp.fulfill()
    }
    action()
    
    wait(for: [exp], timeout: 1.0)
    
    XCTAssertEqual(receivedError as NSError?, expectedError, file: file, line: line)
  }
  
  func uniqueItem() -> FeedItem {
    return FeedItem(id: UUID(), description: "any", location: "any", imageUrl: anyURL())
  }

}
