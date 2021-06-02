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
    let localItems = items.map { LocalFeedItem(id: $0.id, description: $0.description, location: $0.location, imageUrl: $0.imageUrl)}
    
    sut.save(items) { _ in }
    store.completeDeletionSuccessfully()
    
    XCTAssertEqual(store.receivedMessages, [.deleteCachedFeed, .insert(items: localItems, timestamp: timestamp)])
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
    sut?.save([uniqueItem()], completion: { receivedErrors.append($0) })
    
    sut = nil
    store.completeDeletion(with: anyNSError())
    
    XCTAssertTrue(receivedErrors.isEmpty)
  }
  
  func test_save_doesNotDeliverInsertionErrorAfterSUTisDeallocated() {
    let store = FeedStoreSpy()
    var sut: LocalFeedLoader? = LocalFeedLoader(store: store, currentDate: Date.init)
    
    var receivedErrors: [LocalFeedLoader.SaveResult] = []
    sut?.save([uniqueItem()], completion: { receivedErrors.append($0) })
    
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
    sut.save([uniqueItem(), uniqueItem()]) { error in
      receivedError = error
      exp.fulfill()
    }
    action()
    
    wait(for: [exp], timeout: 1.0)
    
    XCTAssertEqual(receivedError as NSError?, expectedError, file: file, line: line)
  }
  
  private func uniqueItem() -> FeedItem {
    return FeedItem(id: UUID(), description: "any", location: "any", imageUrl: anyURL())
  }
  
  private class FeedStoreSpy: FeedStore {
    var deleteCompletions: [DeleteCompletion] = []
    var insertCompletions: [InsertCompletion] = []
    private(set) var receivedMessages: [ReceivedMessage] = []
    
    enum ReceivedMessage: Equatable {
      case deleteCachedFeed
      case insert(items: [LocalFeedItem], timestamp: Date)
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
    
    func insert(items: [LocalFeedItem], timestamp: Date, completion: @escaping InsertCompletion) {
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

}
