//
//  FeedStore.swift
//  EssentialFeed
//
//  Created by Dmitry Tsurkan on 30.05.2021.
//

import Foundation

public protocol FeedStore {
  typealias DeleteCompletion = (Error?) -> Void
  typealias InsertCompletion = (Error?) -> Void
  
  func deleteCachedFeed(_ completion: @escaping DeleteCompletion)
  func insert(_ feed: [LocalFeedImage], timestamp: Date, completion: @escaping InsertCompletion)
}
