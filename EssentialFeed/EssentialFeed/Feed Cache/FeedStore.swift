//
//  FeedStore.swift
//  EssentialFeed
//
//  Created by Dmitry Tsurkan on 30.05.2021.
//

import Foundation

public enum RetrievalResult {
  case failure(_ error: Error)
  case empty
  case found(_ cache: [LocalFeedImage], _ timestamp: Date)
}

public protocol FeedStore {
  typealias DeleteCompletion = (Error?) -> Void
  typealias InsertCompletion = (Error?) -> Void
  typealias RetrieveCompletion = (RetrievalResult) -> Void
  
  func deleteCachedFeed(_ completion: @escaping DeleteCompletion)
  func insert(_ feed: [LocalFeedImage], timestamp: Date, completion: @escaping InsertCompletion)
  func retrieve(completion: @escaping RetrieveCompletion)
}
