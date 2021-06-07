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
  
  // MARK: - Helpers
  
  private func makeSUT(currentDate: @escaping () -> Date = Date.init, file: StaticString = #filePath, line: UInt = #line) -> (store: FeedStoreSpy, sut: LocalFeedLoader) {
    let store = FeedStoreSpy()
    let sut = LocalFeedLoader(store: store, currentDate: currentDate)
    trackForMemoryLeaks(store, file: file, line: line)
    trackForMemoryLeaks(sut, file: file, line: line)
    return (store, sut)
  }
  
  private class FeedStoreSpy: FeedStore {
    var deleteCompletions: [DeleteCompletion] = []
    var insertCompletions: [InsertCompletion] = []
    private(set) var receivedMessages: [ReceivedMessage] = []
    
    enum ReceivedMessage: Equatable {
      case deleteCachedFeed
      case insert(items: [LocalFeedImage], timestamp: Date)
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
    
    func insert(_ items: [LocalFeedImage], timestamp: Date, completion: @escaping InsertCompletion) {
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
