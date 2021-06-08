//
//  FeedStoreSpy.swift
//  EssentialFeedTests
//
//  Created by Dmitry Tsurkan on 07.06.2021.
//

import Foundation
import EssentialFeed

class FeedStoreSpy: FeedStore {
  var deleteCompletions: [DeleteCompletion] = []
  var insertCompletions: [InsertCompletion] = []
  var retrieveCompletions: [RetrieveCompletion] = []
  
  private(set) var receivedMessages: [ReceivedMessage] = []
  
  enum ReceivedMessage: Equatable {
    case deleteCachedFeed
    case insert(items: [LocalFeedImage], timestamp: Date)
    case retrieve
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
  
  func retrieve(completion: @escaping RetrieveCompletion) {
    retrieveCompletions.append(completion)
    receivedMessages.append(.retrieve)
  }
  
  func completeRetrieval(with error: Error, at index: Int = 0) {
    retrieveCompletions[index](error)
  }
  
  func completeRetrievalWithEmptyCache(at index: Int = 0) {
    retrieveCompletions[index](nil)
  }
}
